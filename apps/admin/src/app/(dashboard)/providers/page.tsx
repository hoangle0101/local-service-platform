'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { DataTable, Column } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';
import { Eye, CheckCircle, XCircle, Ban, ShieldCheck } from 'lucide-react';
import { api } from '@/lib/api';
import { Provider } from '@/types/provider';
import { ApiResponse, PaginatedResponse } from '@/types/system';
import { toast } from 'sonner';

export default function ProvidersPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [selectedProvider, setSelectedProvider] = useState<Provider | null>(null);
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    action: 'verify' | 'reject' | 'ban' | 'unban' | 'verify_account' | 'unverify_account' | null;
  }>({ open: false, action: null });

  const statusOptions = ['pending', 'verified', 'rejected'];

  const { data: response, isLoading, refetch } = useQuery({
    queryKey: ['admin-providers', page, searchQuery, statusFilter],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<Provider>>>('/admin/providers', {
        params: {
          page,
          limit: 20,
          search: searchQuery || undefined,
          verificationStatus: statusFilter || undefined,
        },
      });
      return res.data.data;
    },
  });

  const handleProviderAction = async (providerId: string, action: string) => {
    try {
      if (action === 'verify' || action === 'reject') {
        await api.patch(`/admin/providers/${providerId}/verify`, {
          action: action === 'verify' ? 'verified' : 'rejected',
          adminNotes: `Provider ${action === 'verify' ? 'verified' : 'rejected'} by admin`
        });
        toast.success(`Provider ${action === 'verify' ? 'verified' : 'rejected'} successfully`);
      } else if (action === 'ban' || action === 'unban') {
        await api.patch(`/admin/users/${providerId}/ban`, { 
          action: action === 'ban' ? 'ban' : 'unban',
          reason: action === 'ban' ? 'Provider suspended by admin' : 'Provider reactivated by admin'
        });
        toast.success(`Provider ${action === 'ban' ? 'banned' : 'unbanned'} successfully`);
      } else if (action === 'verify_account' || action === 'unverify_account') {
        await api.patch(`/admin/users/${providerId}/verify`, { 
          isVerified: action === 'verify_account'
        });
        toast.success(`User account ${action === 'verify_account' ? 'verified' : 'unverified'} successfully`);
      }
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || `Failed to ${action} provider`);
    }
  };

  const columns: Column<Provider>[] = [
    {
      key: 'userId',
      label: 'ID',
      render: (provider) => (
        <span className="font-mono text-sm">#{provider.userId?.toString().slice(0, 8) || 'N/A'}</span>
      ),
    },
    {
      key: 'displayName',
      label: 'Business Name',
      sortable: true,
      render: (provider) => (
        <div className="flex items-center gap-2">
          {provider.avatarUrl ? (
            <img
              src={provider.avatarUrl}
              alt={provider.displayName}
              className="h-8 w-8 rounded-full object-cover border border-zinc-200"
            />
          ) : (
            <div className="h-8 w-8 rounded-full bg-zinc-100 flex items-center justify-center text-xs text-zinc-400">
              {provider.displayName.charAt(0)}
            </div>
          )}
          <span className="font-medium">{provider.displayName}</span>
        </div>
      ),
    },
    {
      key: 'phone',
      label: 'Phone',
      render: (provider) => (
        <div className="flex items-center gap-1.5">
          <span className="text-sm">{provider.user?.phone || '—'}</span>
          {provider.user?.isVerified ? (
            <span title="Phone Verified">
              <ShieldCheck className="h-3.5 w-3.5 text-green-500" />
            </span>
          ) : (
            <span title="Phone Not Verified">
              <ShieldCheck className="h-3.5 w-3.5 text-zinc-300" />
            </span>
          )}
        </div>
      ),
    },
    {
      key: 'owner',
      label: 'Owner',
      render: (provider) => <span className="text-sm">{provider.user?.profile?.fullName || <span className="text-zinc-400">—</span>}</span>,
    },
    {
      key: 'rating',
      label: 'Rating',
      sortable: true,
      render: (provider) => {
        const avgRating = typeof provider.rating === 'object' && provider.rating?.average
          ? provider.rating.average
          : typeof provider.rating === 'number'
          ? provider.rating
          : 0;
        const reviewCount = typeof provider.rating === 'object' && provider.rating?.count
          ? provider.rating.count
          : provider.totalReviews || 0;
        
        return (
          <div className="flex items-center gap-1 text-sm">
            <span className="text-yellow-500">★</span>
            <span className="font-medium">{Number(avgRating).toFixed(1)}</span>
            <span className="text-zinc-400">({reviewCount})</span>
          </div>
        );
      },
    },
    {
      key: 'verificationStatus',
      label: 'Work Status',
      sortable: true,
      render: (provider) => <StatusBadge status={provider.verificationStatus} />,
    },
    {
      key: 'userStatus',
      label: 'Account',
      render: (provider) => <StatusBadge status={provider.user?.status || 'active'} />,
    },
    {
      key: 'createdAt',
      label: 'Joined',
      sortable: true,
      render: (provider) => <span className="text-sm">{new Date(provider.createdAt).toLocaleDateString('vi-VN')}</span>,
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (provider) => (
        <div className="flex items-center gap-1">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => router.push(`/providers/${provider.userId}`)}
          >
            <Eye className="h-4 w-4" />
          </Button>
          {provider.verificationStatus !== 'verified' && (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedProvider(provider);
                setActionDialog({ open: true, action: 'verify' });
              }}
              title="Accept/Approve Provider"
            >
              <CheckCircle className="h-4 w-4 text-green-500" />
            </Button>
          )}
          {provider.verificationStatus !== 'rejected' && (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedProvider(provider);
                setActionDialog({ open: true, action: 'reject' });
              }}
              title="Reject Provider"
            >
              <XCircle className="h-4 w-4 text-red-500" />
            </Button>
          )}
          {provider.user?.status === 'active' ? (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedProvider(provider);
                setActionDialog({ open: true, action: 'ban' });
              }}
              title="Ban Provider Account"
            >
              <Ban className="h-4 w-4 text-red-500" />
            </Button>
          ) : provider.user?.status === 'banned' ? (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedProvider(provider);
                setActionDialog({ open: true, action: 'unban' });
              }}
              title="Unban Provider Account"
            >
              <CheckCircle className="h-4 w-4 text-green-500" />
            </Button>
          ) : null}

          {/* Phone verification toggle */}
          {provider.user && (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedProvider(provider);
                setActionDialog({ 
                  open: true, 
                  action: provider.user.isVerified ? 'unverify_account' : 'verify_account' 
                });
              }}
              title={provider.user.isVerified ? "Unverify Phone" : "Verify Phone Manually"}
            >
              <ShieldCheck className={`h-4 w-4 ${provider.user.isVerified ? 'text-blue-500' : 'text-zinc-400'}`} />
            </Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">Providers Management</h2>
        <p className="text-zinc-600">Manage service providers and applications</p>
      </div>

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
            {status.charAt(0).toUpperCase() + status.slice(1)}
          </Button>
        ))}
      </div>

      <DataTable
        data={response?.data || []}
        columns={columns}
        searchable
        searchPlaceholder="Search by business name, phone, or owner..."
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
        emptyMessage="No providers found"
      />

      <ConfirmDialog
        open={actionDialog.open}
        onOpenChange={(open) => setActionDialog({ open, action: null })}
        title={
          actionDialog.action === 'verify'
            ? 'Approve Provider Business'
            : actionDialog.action === 'reject'
            ? 'Reject Provider Application'
            : actionDialog.action === 'unban'
            ? 'Unban Provider Account'
            : actionDialog.action === 'verify_account'
            ? 'Verify User Account'
            : actionDialog.action === 'unverify_account'
            ? 'Remove User Verification'
            : 'Ban Provider Account'
        }
        description={
          actionDialog.action === 'verify'
            ? `Approve ${selectedProvider?.displayName} as a verified service provider?`
            : actionDialog.action === 'reject'
            ? `Reject or revoke ${selectedProvider?.displayName}'s provider status?`
            : actionDialog.action === 'unban'
            ? `Reactivate account for ${selectedProvider?.displayName}?`
            : actionDialog.action === 'verify_account'
            ? `Manually verify the user account for ${selectedProvider?.displayName}?`
            : actionDialog.action === 'unverify_account'
            ? `Remove manual verification from the user account for ${selectedProvider?.displayName}?`
            : `Are you sure you want to ban ${selectedProvider?.displayName}? This will prevent them from using the platform.`
        }
        confirmLabel={
          actionDialog.action === 'verify'
            ? 'Approve'
            : actionDialog.action === 'reject'
            ? 'Reject'
            : actionDialog.action === 'unban'
            ? 'Unban'
            : actionDialog.action === 'verify_account'
            ? 'Verify'
            : actionDialog.action === 'unverify_account'
            ? 'Remove Verification'
            : 'Ban'
        }
        variant={
          actionDialog.action === 'reject' || 
          actionDialog.action === 'ban' || 
          actionDialog.action === 'unverify_account' 
            ? 'destructive' 
            : 'default'
        }
        onConfirm={async () => {
          if (selectedProvider && actionDialog.action) {
            await handleProviderAction(selectedProvider.userId, actionDialog.action);
          }
        }}
      />
    </div>
  );
}
