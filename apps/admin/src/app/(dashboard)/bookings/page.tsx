'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { DataTable, Column } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { Eye, Calendar } from 'lucide-react';
import { api } from '@/lib/api';
import { Booking } from '@/types/booking';
import { ApiResponse, PaginatedResponse } from '@/types/system';

export default function BookingsPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('');

  const { data: response, isLoading } = useQuery({
    queryKey: ['admin-bookings', page, searchQuery, statusFilter],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<Booking>>>('/admin/bookings', {
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

  // Format currency
  const formatCurrency = (amount: number | string) => {
    const numAmount = typeof amount === 'string' ? parseFloat(amount) : amount;
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(numAmount);
  };

  const columns: Column<Booking>[] = [
    {
      key: 'id',
      label: 'Booking ID',
      render: (booking) => (
        <span className="font-mono text-sm">#{booking.id.slice(0, 8)}</span>
      ),
    },
    {
      key: 'customer',
      label: 'Customer',
      render: (booking) => (
        <div>
          <div className="font-medium">
            {booking.customer?.profile?.fullName || 'N/A'}
          </div>
          <div className="text-sm text-zinc-500">{booking.customer?.phone}</div>
        </div>
      ),
    },
    {
      key: 'provider',
      label: 'Provider',
      render: (booking) => (
        <div>
          <div className="font-medium">{booking.provider?.businessName}</div>
          <div className="text-sm text-zinc-500">{booking.provider?.user?.phone}</div>
        </div>
      ),
    },
    {
      key: 'service',
      label: 'Service',
      render: (booking) => booking.service?.name || 'N/A',
    },
    {
      key: 'scheduledAt',
      label: 'Scheduled',
      sortable: true,
      render: (booking) => (
        <div className="text-sm">
          {new Date(booking.scheduledAt).toLocaleString('vi-VN')}
        </div>
      ),
    },
    {
      key: 'totalAmount',
      label: 'Amount',
      sortable: true,
      render: (booking) => (
        <span className="font-medium">{formatCurrency(booking.totalAmount)}</span>
      ),
    },
    {
      key: 'status',
      label: 'Status',
      sortable: true,
      render: (booking) => <StatusBadge status={booking.status} />,
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (booking) => (
        <Button
          variant="ghost"
          size="sm"
          onClick={() => router.push(`/bookings/${booking.id}`)}
        >
          <Eye className="h-4 w-4" />
        </Button>
      ),
    },
  ];

  const statusOptions = ['pending', 'accepted', 'in_progress', 'completed', 'cancelled', 'disputed'];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Bookings Management</h2>
          <p className="text-zinc-600">Monitor and manage all bookings</p>
        </div>
        <Button variant="outline">
          <Calendar className="h-4 w-4 mr-2" />
          Export Report
        </Button>
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
        searchPlaceholder="Search bookings..."
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
        emptyMessage="No bookings found"
      />
    </div>
  );
}
