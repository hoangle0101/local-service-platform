'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { DataTable, Column } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';
import { CheckCircle, XCircle } from 'lucide-react';
import { api } from '@/lib/api';
import { WithdrawalRequest } from '@/types/payment';
import { ApiResponse, PaginatedResponse } from '@/types/system';
import { toast } from 'sonner';

export default function WithdrawalsPage() {
  const [page, setPage] = useState(1);
  const [selectedRequest, setSelectedRequest] = useState<WithdrawalRequest | null>(null);
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    action: 'approve' | 'reject' | null;
  }>({ open: false, action: null });

  const { data: response, isLoading, refetch } = useQuery({
    queryKey: ['admin-withdrawals', page],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<WithdrawalRequest>>>('/admin/withdrawals', {
        params: {
          page,
          limit: 20,
        },
      });
      return res.data.data;
    },
  });

  const handleAction = async (id: string, action: 'approve' | 'reject') => {
    try {
      if (action === 'approve') {
        await api.patch(`/admin/withdrawals/${id}/approve`, {
          approvalNotes: 'Approved by admin',
        });
        toast.success('Withdrawal approved successfully');
      } else {
        await api.patch(`/admin/withdrawals/${id}/reject`, {
          rejectionReason: 'Rejected by admin',
          refundToWallet: true,
        });
        toast.success('Withdrawal rejected and refunded');
      }
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || `Failed to ${action} withdrawal`);
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

  const columns: Column<WithdrawalRequest>[] = [
    {
      key: 'id',
      label: 'ID',
      render: (req) => <span className="font-mono text-sm">#{req.id.slice(0, 8)}</span>,
    },
    {
      key: 'wallet',
      label: 'User',
      render: (req) => (
        <div>
          <div className="font-medium">{req.wallet?.user?.profile?.fullName || 'N/A'}</div>
          <div className="text-sm text-zinc-500">{req.wallet?.user?.phone}</div>
        </div>
      ),
    },
    {
      key: 'amount',
      label: 'Amount',
      sortable: true,
      render: (req) => (
        <span className="font-medium text-lg text-red-600">
          {formatCurrency(req.amount)}
        </span>
      ),
    },
    {
      key: 'metadata',
      label: 'Bank Details',
      render: (req) => (
        <div className="text-sm">
          <div>{req.metadata?.bankName}</div>
          <div className="font-mono text-zinc-500">{req.metadata?.bankAccount}</div>
        </div>
      ),
    },
    {
      key: 'status',
      label: 'Status',
      render: (req) => <StatusBadge status={req.status} />,
    },
    {
      key: 'createdAt',
      label: 'Date',
      render: (req) => new Date(req.createdAt).toLocaleString('vi-VN'),
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (req) => (
        req.status === 'pending' && (
          <div className="flex gap-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedRequest(req);
                setActionDialog({ open: true, action: 'approve' });
              }}
            >
              <CheckCircle className="h-4 w-4 text-green-500" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedRequest(req);
                setActionDialog({ open: true, action: 'reject' });
              }}
            >
              <XCircle className="h-4 w-4 text-red-500" />
            </Button>
          </div>
        )
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">Withdrawals</h2>
        <p className="text-zinc-600">Manage withdrawal requests</p>
      </div>

      <DataTable
        data={response?.data || []}
        columns={columns}
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
        emptyMessage="No withdrawal requests found"
      />

      <ConfirmDialog
        open={actionDialog.open}
        onOpenChange={(open) => setActionDialog({ open, action: null })}
        title={actionDialog.action === 'approve' ? 'Approve Withdrawal' : 'Reject Withdrawal'}
        description={`Are you sure you want to ${actionDialog.action} this withdrawal request of ${selectedRequest ? formatCurrency(selectedRequest.amount) : ''}?`}
        confirmLabel={actionDialog.action === 'approve' ? 'Approve' : 'Reject'}
        variant={actionDialog.action === 'approve' ? 'default' : 'destructive'}
        onConfirm={async () => {
          if (selectedRequest && actionDialog.action) {
            await handleAction(selectedRequest.id, actionDialog.action);
          }
        }}
      />
    </div>
  );
}
