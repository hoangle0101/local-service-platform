'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { DataTable, Column } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { Download } from 'lucide-react';
import { api } from '@/lib/api';
import { Payment } from '@/types/payment';
import { ApiResponse, PaginatedResponse } from '@/types/system';

export default function PaymentsPage() {
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');

  const { data: response, isLoading } = useQuery({
    queryKey: ['admin-payments', page, searchQuery],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<Payment>>>('/admin/payments', {
        params: {
          page,
          limit: 20,
          search: searchQuery || undefined,
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

  const columns: Column<Payment>[] = [
    {
      key: 'id',
      label: 'Payment ID',
      render: (payment) => (
        <span className="font-mono text-sm">#{payment.id.slice(0, 8)}</span>
      ),
    },
    {
key: 'booking',
      label: 'Customer',
      render: (payment) => (
        <div>
          <div className="font-medium">
            {payment.booking?.customer?.profile?.fullName || 'N/A'}
          </div>
          <div className="text-sm text-zinc-500">{payment.booking?.customer?.phone}</div>
        </div>
      ),
    },
    {
      key: 'gateway',
      label: 'Gateway',
      render: (payment) => (
        <span className="capitalize text-sm px-2 py-1 rounded bg-zinc-100">
          {payment.gateway}
        </span>
      ),
    },
    {
      key: 'amount',
      label: 'Amount',
      sortable: true,
      render: (payment) => (
        <span className="font-medium text-green-600">
          {formatCurrency(payment.amount)}
        </span>
      ),
    },
    {
      key: 'status',
      label: 'Status',
      sortable: true,
      render: (payment) => <StatusBadge status={payment.status} />,
    },
    {
      key: 'gatewayTransactionId',
      label: 'Transaction ID',
      render: (payment) => (
        payment.gatewayTransactionId 
          ? <span className="font-mono text-xs">{payment.gatewayTransactionId}</span>
          : <span className="text-zinc-400">—</span>
      ),
    },
    {
      key: 'createdAt',
      label: 'Date',
      sortable: true,
      render: (payment) => (
        <div className="text-sm">
          {new Date(payment.createdAt).toLocaleString('vi-VN')}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Payments & Transactions</h2>
          <p className="text-zinc-600">Monitor all financial transactions</p>
        </div>
        <Button variant="outline">
          <Download className="h-4 w-4 mr-2" />
          Export Report
        </Button>
      </div>

      <DataTable
        data={response?.data || []}
        columns={columns}
        searchable
        searchPlaceholder="Search payments..."
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
        emptyMessage="No payments found"
      />
    </div>
  );
}
