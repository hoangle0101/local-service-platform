'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { DataTable, Column } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';
import { Eye, Ban, CheckCircle } from 'lucide-react';
import { api } from '@/lib/api';
import { User } from '@/types/user';
import { ApiResponse, PaginatedResponse } from '@/types/system';
import { toast } from 'sonner';

export default function UsersPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    action: 'ban' | 'unban' | null;
  }>({ open: false, action: null });

  const { data: response, isLoading, refetch } = useQuery({
    queryKey: ['admin-users', page, searchQuery],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<User>>>('/admin/users', {
        params: {
          page,
          limit: 20,
          search: searchQuery || undefined,
        },
      });
      return res.data.data;
    },
  });

  const handleStatusChange = async (userId: string, action: 'ban' | 'unban') => {
    try {
      await api.patch(`/admin/users/${userId}/ban`, { 
        action,
        reason: action === 'ban' ? 'Banned by admin' : 'Unbanned by admin'
      });
      toast.success(`User ${action === 'ban' ? 'banned' : 'unbanned'} successfully`);
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || `Failed to ${action} user`);
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
      render: (user) => (
        <span>{user.profile?.fullName || <span className="text-zinc-400">Not set</span>}</span>
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
            onClick={() => router.push(`/users/${user.id}`)}
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
            >
              <CheckCircle className="h-4 w-4 text-green-500" />
            </Button>
          ) : null}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">Users Management</h2>
        <p className="text-zinc-600">Manage all platform users</p>
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
        emptyMessage="No users found"
      />

      <ConfirmDialog
        open={actionDialog.open}
        onOpenChange={(open) => setActionDialog({ open, action: null })}
        title={actionDialog.action === 'ban' ? 'Ban User' : 'Unban User'}
        description={
          actionDialog.action === 'ban'
            ? `Are you sure you want to ban user ${selectedUser?.phone}? They will not be able to access the platform.`
            : `Are you sure you want to unban user ${selectedUser?.phone}?`
        }
        confirmLabel={actionDialog.action === 'ban' ? 'Ban User' : 'Unban User'}
        variant={actionDialog.action === 'ban' ? 'destructive' : 'default'}
        onConfirm={async () => {
          if (selectedUser && actionDialog.action) {
            await handleStatusChange(selectedUser.id, actionDialog.action);
          }
        }}
      />
    </div>
  );
}
