'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { DataTable, Column } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';
import { Plus, Edit, Trash2, Eye } from 'lucide-react';
import { api } from '@/lib/api';
import { Service } from '@/types/provider';
import { ApiResponse, PaginatedResponse } from '@/types/system';
import { toast } from 'sonner';

export default function ServicesPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [selectedService, setSelectedService] = useState<Service | null>(null);
  const [deleteDialog, setDeleteDialog] = useState(false);

  const { data: response, isLoading, refetch } = useQuery({
    queryKey: ['admin-services', page, searchQuery, statusFilter],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<Service>>>('/services/search', {
        params: {
          page,
          limit: 20,
          search: searchQuery || undefined,
          isActive: statusFilter === 'active' ? true : statusFilter === 'inactive' ? false : undefined,
        },
      });
      return res.data.data;
    },
  });

  const handleDelete = async (serviceId: number) => {
    try {
      await api.delete(`/services/${serviceId}`);
      toast.success('Service deleted successfully');
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to delete service');
    }
  };

  const handleToggleActive = async (service: Service) => {
    try {
      await api.put(`/services/${service.id}`, {
        ...service,
        isActive: !service.isActive,
      });
      toast.success(`Service ${!service.isActive ? 'activated' : 'deactivated'}`);
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to update service');
    }
  };

  // Format currency
  const formatCurrency = (amount: number | string) => {
    const numAmount = typeof amount === 'string' ? parseFloat(amount) : amount;
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(numAmount);
  };

  const columns: Column<Service>[] = [
    {
      key: 'id',
      label: 'ID',
      render: (service) => <span className="font-mono text-sm">#{service.id}</span>,
    },
    {
      key: 'name',
      label: 'Service Name',
      sortable: true,
      render: (service) => (
        <div className="flex items-center gap-2">
          {service.imageUrl && (
            <img
              src={service.imageUrl}
              alt={service.name}
              className="h-10 w-10 rounded object-cover"
            />
          )}
          <div>
            <div className="font-medium">{service.name}</div>
            {service.description && (
              <div className="text-xs text-zinc-500 line-clamp-1">
                {service.description}
              </div>
            )}
          </div>
        </div>
      ),
    },
    {
      key: 'category',
      label: 'Category',
      render: (service) => service.category?.name || '—',
    },
    {
      key: 'basePrice',
      label: 'Base Price',
      sortable: true,
      render: (service) => <span className="font-medium">{formatCurrency(service.basePrice)}</span>,
    },
    {
      key: 'durationMinutes',
      label: 'Duration',
      render: (service) => <span>{service.durationMinutes} min</span>,
    },
    {
      key: 'isActive',
      label: 'Status',
      sortable: true,
      render: (service) => (
        <StatusBadge status={service.isActive ? 'active' : 'inactive'} />
      ),
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (service) => (
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => router.push(`/services/${service.id}`)}
          >
            <Eye className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => handleToggleActive(service)}
            title={service.isActive ? 'Deactivate' : 'Activate'}
          >
            {service.isActive ? '✓' : '✗'}
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => {
              setSelectedService(service);
              setDeleteDialog(true);
            }}
          >
            <Trash2 className="h-4 w-4 text-red-500" />
          </Button>
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Services Management</h2>
          <p className="text-zinc-600">Manage all available services</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => router.push('/services/categories')}>
            Manage Categories
          </Button>
          <Button onClick={() => router.push('/services/new')}>
            <Plus className="h-4 w-4 mr-2" />
            Add Service
          </Button>
        </div>
      </div>

      <div className="flex gap-2">
        <Button
          variant={statusFilter === '' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setStatusFilter('')}
        >
          All
        </Button>
        <Button
          variant={statusFilter === 'active' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setStatusFilter('active')}
        >
          Active
        </Button>
        <Button
          variant={statusFilter === 'inactive' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setStatusFilter('inactive')}
        >
          Inactive
        </Button>
      </div>

      <DataTable
        data={response?.data || []}
        columns={columns}
        searchable
        searchPlaceholder="Search services..."
        onSearch={setSearchQuery}
        pagination={
          response?.pagination
            ? {
                page,
                pageSize: response.pagination.limit,
                total: response.pagination.total,
                onPageChange: setPage,
              }
            : undefined
        }
        isLoading={isLoading}
        emptyMessage="No services found"
      />

      <ConfirmDialog
        open={deleteDialog}
        onOpenChange={setDeleteDialog}
        title="Delete Service"
        description={`Are you sure you want to delete "${selectedService?.name}"? This action cannot be undone.`}
        confirmLabel="Delete"
        variant="destructive"
        onConfirm={async () => {
          if (selectedService) {
            await handleDelete(selectedService.id);
          }
        }}
      />
    </div>
  );
}
