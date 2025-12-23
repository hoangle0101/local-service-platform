'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { DataTable, Column } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';
import { Eye, CheckCircle, XCircle, Ban } from 'lucide-react';
import { api } from '@/lib/api';
import { Provider } from '@/types/provider';
import { ApiResponse, PaginatedResponse } from '@/types/system';
import { toast } from 'sonner';

export default function ProvidersPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedProvider, setSelectedProvider] = useState<Provider | null>(null);
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    action: 'verify' | 'reject' | 'ban' | null;
  }>({ open: false, action: null });

  const { data: response, isLoading, refetch } = useQuery({
    queryKey: ['admin-providers', page, searchQuery],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<Provider>>>('/admin/providers', {
        params: {
          page,
          limit: 20,
          search: searchQuery || undefined,
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
      } else if (action === 'ban') {
        await api.patch(`/admin/users/${providerId}/ban`, { 
          action: 'ban',
          reason: 'Provider suspended by admin'
        });
        toast.success('Provider banned successfully');
      }
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || `Failed to ${action} provider`);
    }
  };

  const columns: Column<Provider>[] = [
    {
      key: 'userId',
      label: 'Provider ID',
      render: (provider) => (
        <span className="font-mono text-sm">#{provider.userId.slice(0, 8)}</span>
      ),
    },
    {
      key: 'displayName',
      label: 'Business Name',
      sortable: true,
      render: (provider) => (
        <div className="flex items-center gap-2">
          {provider.avatarUrl && (
            <img
              src={provider.avatarUrl}
              alt={provider.displayName}
              className="h-8 w-8 rounded-full object-cover"
            />
          )}
          <span className="font-medium">{provider.displayName}</span>
        </div>
      ),
    },
    {
      key: 'user',
      label: 'Contact',
      render: (provider) => (
        <div className="text-sm">
          <div>{provider.user?.phone}</div>
          {provider.user?.profile?.fullName && (
            <div className="text-zinc-500">{provider.user.profile.fullName}</div>
          )}
        </div>
      ),
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
          <div className="flex items-center gap-1">
            <span className="text-yellow-500">★</span>
            <span className="font-medium">{Number(avgRating).toFixed(1)}</span>
            <span className="text-zinc-400 text-sm">({reviewCount})</span>
          </div>
        );
      },
    },
    {
      key: 'verificationStatus',
      label: 'Verification',
      sortable: true,
      render: (provider) => <StatusBadge status={provider.verificationStatus} />,
    },
    {
      key: 'availabilityStatus',
      label: 'Availability',
      render: (provider) => <StatusBadge status={provider.availabilityStatus} />,
    },
    {
      key: 'createdAt',
      label: 'Joined',
      sortable: true,
      render: (provider) => new Date(provider.createdAt).toLocaleDateString('vi-VN'),
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (provider) => (
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => router.push(`/providers/${provider.userId}`)}
          >
            <Eye className="h-4 w-4" />
          </Button>
          {provider.verificationStatus === 'pending' && (
            <>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  setSelectedProvider(provider);
                  setActionDialog({ open: true, action: 'verify' });
                }}
              >
                <CheckCircle className="h-4 w-4 text-green-500" />
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  setSelectedProvider(provider);
                  setActionDialog({ open: true, action: 'reject' });
                }}
              >
                <XCircle className="h-4 w-4 text-red-500" />
              </Button>
            </>
          )}
          {provider.verificationStatus === 'verified' && (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedProvider(provider);
                setActionDialog({ open: true, action: 'ban' });
              }}
            >
              <Ban className="h-4 w-4 text-red-500" />
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

      <DataTable
        data={response?.data || []}
        columns={columns}
        searchable
        searchPlaceholder="Search by business name or phone..."
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
            ? 'Verify Provider'
            : actionDialog.action === 'reject'
            ? 'Reject Provider'
            : 'Ban Provider'
        }
        description={
          actionDialog.action === 'verify'
            ? `Verify ${selectedProvider?.displayName} as a service provider?`
            : actionDialog.action === 'reject'
            ? `Reject ${selectedProvider?.displayName}'s provider application?`
            : `Ban ${selectedProvider?.displayName}? They will not be able to accept new bookings.`
        }
        confirmLabel={
          actionDialog.action === 'verify'
            ? 'Verify'
            : actionDialog.action === 'reject'
            ? 'Reject'
            : 'Ban'
        }
        variant={actionDialog.action === 'verify' ? 'default' : 'destructive'}
        onConfirm={async () => {
          if (selectedProvider && actionDialog.action) {
            await handleProviderAction(selectedProvider.userId, actionDialog.action);
          }
        }}
      />
    </div>
  );
}
