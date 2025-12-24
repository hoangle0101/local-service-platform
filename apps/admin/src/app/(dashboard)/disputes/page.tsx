'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { DataTable, Column } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { Eye, AlertTriangle } from 'lucide-react';
import { api } from '@/lib/api';
import { Dispute } from '@/types/dispute';
import { ApiResponse, PaginatedResponse } from '@/types/system';

export default function DisputesPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('');

  const { data: response, isLoading } = useQuery({
    queryKey: ['admin-disputes', page, searchQuery, statusFilter],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<Dispute>>>('/admin/disputes', {
        params: {
          page,
          limit: 20,
          search: searchQuery || undefined,
          status: statusFilter || undefined,
        },
      });
      return res.data.data;
    },
  });

  const columns: Column<Dispute>[] = [
    {
      key: 'id',
      label: 'Dispute ID',
      render: (dispute) => (
        <span className="font-mono text-sm">#{dispute.id?.toString().slice(0, 8) || 'N/A'}</span>
      ),
    },
    {
      key: 'booking',
      label: 'Booking',
      render: (dispute: any) => (
        <div>
          <div className="font-medium">#{dispute.bookingId?.toString().slice(0, 8) || 'N/A'}</div>
          <div className="text-sm text-zinc-500">{dispute.booking?.serviceName || dispute.booking?.service?.name || 'N/A'}</div>
        </div>
      ),
    },
    {
      key: 'reporter',
      label: 'Reporter',
      render: (dispute: any) => (
        <div>
          <div className="font-medium">
            {dispute.reporter?.profile?.fullName || dispute.booking?.customerPhone || 'N/A'}
          </div>
          <div className="text-sm text-zinc-500">{dispute.reporter?.phone || dispute.booking?.customerPhone}</div>
        </div>
      ),
    },
    {
      key: 'reason',
      label: 'Reason',
      render: (dispute) => (
        <span className="text-sm line-clamp-2">{dispute.reason}</span>
      ),
    },
    {
      key: 'status',
      label: 'Status',
      sortable: true,
      render: (dispute) => <StatusBadge status={dispute.status} />,
    },
    {
      key: 'createdAt',
      label: 'Created',
      sortable: true,
      render: (dispute) => (
        <div className="text-sm">
          {new Date(dispute.createdAt).toLocaleDateString('vi-VN')}
        </div>
      ),
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (dispute) => (
        <Button
          variant="ghost"
          size="sm"
          onClick={() => router.push(`/disputes/${dispute.id}`)}
        >
          <Eye className="h-4 w-4" />
        </Button>
      ),
    },
  ];

  const statusOptions = ['open', 'under_review', 'resolved', 'closed'];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight flex items-center gap-2">
            <AlertTriangle className="h-8 w-8 text-yellow-500" />
            Disputes Management
          </h2>
          <p className="text-zinc-600">Handle booking disputes and conflicts</p>
        </div>
      </div>

      {/* Status Filters */}
      <div className="flex gap-2">
        <Button
          variant={statusFilter === '' ? 'default' : 'outline'}
          size="sm"
          onClick={() => setStatusFilter('')}
        >
          All
        </Button>
        {statusOptions.map((status) => (
          <Button
            key={status}
            variant={statusFilter === status ? 'default' : 'outline'}
            size="sm"
            onClick={() => setStatusFilter(status)}
          >
            {status.replace('_', ' ')}
          </Button>
        ))}
      </div>

      <DataTable
        data={response?.data || []}
        columns={columns}
        searchable
        searchPlaceholder="Search disputes..."
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
        emptyMessage="No disputes found"
      />
    </div>
  );
}
