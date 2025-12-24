'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { DataTable, Column } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';
import { Eye, Ban, CheckCircle, XCircle, ShieldCheck } from 'lucide-react';
import { api } from '@/lib/api';
import { User } from '@/types/user';
import { ApiResponse, PaginatedResponse } from '@/types/system';
import { toast } from 'sonner';

export default function CustomersPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    action: 'ban' | 'unban' | 'verify' | 'unverify' | null;
  }>({ open: false, action: null });

  const { data: response, isLoading, refetch } = useQuery({
    queryKey: ['admin-users', page, searchQuery],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<User>>>('/admin/users', {
        params: {
          page,
          limit: 20,
          search: searchQuery || undefined,
          role: 'customer',
        },
      });
      return res.data.data;
    },
  });

  const handleStatusChange = async (userId: string, action: 'ban' | 'unban' | 'verify' | 'unverify') => {
    try {
      if (action === 'ban' || action === 'unban') {
        await api.patch(`/admin/users/${userId}/ban`, {
          action,
          reason: action === 'ban' ? 'Banned by admin' : 'Unbanned by admin'
        });
        toast.success(`User ${action === 'ban' ? 'banned' : 'unbanned'} successfully`);
      } else {
        await api.patch(`/admin/users/${userId}/verify`, {
          isVerified: action === 'verify'
        });
        toast.success(`User ${action === 'verify' ? 'verified' : 'unverified'} successfully`);
      }
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || `Failed to perform action`);
    }
  };

  const columns: Column<User>[] = [
    {
      key: 'id',
      label: 'User ID',
      render: (user) => (
        <span className="font-mono text-sm">#{user.id.slice(0, 8)}</span>
      ),
    },
    {
      key: 'phone',
      label: 'Phone',
      sortable: true,
    },
    {
      key: 'email',
      label: 'Email',
      render: (user) => user.email || <span className="text-zinc-400">—</span>,
    },
    {
      key: 'profile',
      label: 'Full Name',
      render: (user: any) => (
        <span>{user.fullName || user.profile?.fullName || <span className="text-zinc-400">Not set</span>}</span>
      ),
    },
    {
      key: 'roles',
      label: 'Role',
      render: (user) => (
        <span className="capitalize text-sm px-2 py-1 rounded bg-zinc-100 font-medium">
          {user.roles && user.roles.length > 0
            ? user.roles[0].replace('_', ' ')
            : 'No Role'}
        </span>
      ),
    },
    {
      key: 'status',
      label: 'Status',
      sortable: true,
      render: (user) => <StatusBadge status={user.status} />,
    },
    {
      key: 'isVerified',
      label: 'Verified',
      render: (user) => (
        <span className={user.isVerified ? 'text-green-600' : 'text-zinc-400'}>
          {user.isVerified ? '✓ Yes' : '✗ No'}
        </span>
      ),
    },
    {
      key: 'createdAt',
      label: 'Joined',
      sortable: true,
      render: (user) => new Date(user.createdAt).toLocaleDateString('vi-VN'),
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (user) => (
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => router.push(`/customers/${user.id}`)}
          >
            <Eye className="h-4 w-4" />
          </Button>
          {user.status === 'active' ? (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedUser(user);
                setActionDialog({ open: true, action: 'ban' });
              }}
              title="Ban User"
            >
              <Ban className="h-4 w-4 text-red-500" />
            </Button>
          ) : user.status === 'banned' ? (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedUser(user);
                setActionDialog({ open: true, action: 'unban' });
              }}
              title="Unban User"
            >
              <CheckCircle className="h-4 w-4 text-green-500" />
            </Button>
          ) : null}
          {!user.isVerified ? (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedUser(user);
                setActionDialog({ open: true, action: 'verify' });
              }}
              title="Verify Account"
            >
              <ShieldCheck className="h-4 w-4 text-blue-500" />
            </Button>
          ) : (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedUser(user);
                setActionDialog({ open: true, action: 'unverify' });
              }}
              title="Unverify Account"
            >
              <XCircle className="h-4 w-4 text-orange-500" />
            </Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">Customers Management</h2>
        <p className="text-zinc-600">Manage all platform customers</p>
      </div>

      <DataTable
        data={response?.data || []}
        columns={columns}
        searchable
        searchPlaceholder="Search by phone, email, or name..."
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
        emptyMessage="No customers found"
      />

      <ConfirmDialog
        open={actionDialog.open}
        onOpenChange={(open) => setActionDialog({ open, action: null })}
        title={
          actionDialog.action === 'ban'
            ? 'Ban User'
            : actionDialog.action === 'unban'
              ? 'Unban User'
              : actionDialog.action === 'verify'
                ? 'Verify Account'
                : 'Unverify Account'
        }
        description={
          actionDialog.action === 'ban'
            ? `Are you sure you want to ban user ${selectedUser?.phone}? They will not be able to access the platform.`
            : actionDialog.action === 'unban'
              ? `Are you sure you want to unban user ${selectedUser?.phone}?`
              : actionDialog.action === 'verify'
                ? `Manually verify account for ${selectedUser?.phone}?`
                : `Remove verification status for ${selectedUser?.phone}?`
        }
        confirmLabel={
          actionDialog.action === 'ban'
            ? 'Ban User'
            : actionDialog.action === 'unban'
              ? 'Unban'
              : actionDialog.action === 'verify'
                ? 'Verify'
                : 'Remove Verification'
        }
        variant={actionDialog.action === 'ban' || actionDialog.action === 'unverify' ? 'destructive' : 'default'}
        onConfirm={async () => {
          if (selectedUser && actionDialog.action) {
            await handleStatusChange(selectedUser.id, actionDialog.action);
          }
        }}
      />
    </div>
  );
}
