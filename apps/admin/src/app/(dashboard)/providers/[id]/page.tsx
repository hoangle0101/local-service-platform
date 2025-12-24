'use client';

import { useQuery } from '@tanstack/react-query';
import { useParams, useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { ArrowLeft, Star, TrendingUp, CheckCircle, XCircle, Phone, Mail } from 'lucide-react';
import { api } from '@/lib/api';
import { Provider } from '@/types/provider';
import { ApiResponse } from '@/types/system';
import { toast } from 'sonner';

export default function ProviderDetailPage() {
  const params = useParams();
  const router = useRouter();
  const providerId = params.id as string;

  const { data: response, isLoading, refetch } = useQuery({
    queryKey: ['admin-provider-detail', providerId],
    queryFn: async () => {
      const res = await api.get<ApiResponse<Provider>>(`/admin/providers/${providerId}`);
      return res.data;
    },
  });

  const provider = response?.data;

  const handleAction = async (action: 'verified' | 'rejected') => {
    try {
      await api.patch(`/admin/providers/${providerId}/verify`, {
        action,
        adminNotes: `Provider ${action} by admin`
      });
      toast.success(`Provider ${action === 'verified' ? 'approved' : 'rejected'} successfully`);
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || `Failed to ${action} provider`);
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

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="h-8 w-48 bg-zinc-200 animate-pulse rounded" />
        <div className="grid gap-6 md:grid-cols-2">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-48 bg-zinc-100 animate-pulse rounded-lg" />
          ))}
        </div>
      </div>
    );
  }

  if (!provider) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <p className="text-lg text-zinc-600">Provider not found</p>
          <Button onClick={() => router.push('/providers')} className="mt-4">
            Back to Providers
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => router.push('/providers')}
          >
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div>
            <h2 className="text-3xl font-bold tracking-tight">{provider.displayName}</h2>
            <p className="text-zinc-600">Provider #{provider.id.slice(0, 8)}</p>
          </div>
        </div>
        {provider.verificationStatus === 'pending' && (
          <div className="flex gap-2">
            <Button variant="default" onClick={() => handleAction('verified')}>
              <CheckCircle className="h-4 w-4 mr-2" />
              Approve
            </Button>
            <Button variant="destructive" onClick={() => handleAction('rejected')}>
              <XCircle className="h-4 w-4 mr-2" />
              Reject
            </Button>
          </div>
        )}
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <Card className="bg-gradient-to-br from-yellow-50 to-orange-50">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Rating</CardTitle>
            <Star className="h-4 w-4 text-yellow-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {typeof provider.rating === 'object' && provider.rating?.average
                ? provider.rating.average.toFixed(1)
                : typeof provider.rating === 'number'
                ? provider.rating.toFixed(1)
                : '0.0'
              }
            </div>
            <p className="text-xs text-zinc-600">
              {provider.totalReviews || 0} reviews
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-green-50 to-emerald-50">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Response Time</CardTitle>
            <TrendingUp className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {provider.responseTime ? `${provider.responseTime}m` : 'N/A'}
            </div>
            <p className="text-xs text-zinc-600">Average response</p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-blue-50 to-indigo-50">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Completion Rate</CardTitle>
            <TrendingUp className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {provider.completionRate || '0%'}
            </div>
            <p className="text-xs text-zinc-600">Jobs completed</p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-purple-50 to-pink-50">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Services</CardTitle>
            <TrendingUp className="h-4 w-4 text-purple-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{provider.services?.length || 0}</div>
            <p className="text-xs text-zinc-600">Active services</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Business Information */}
        <Card>
          <CardHeader>
            <CardTitle>Business Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {provider.avatarUrl && (
              <div className="flex justify-center">
                <img
                  src={provider.avatarUrl}
                  alt={provider.displayName}
                  className="h-24 w-24 rounded-full object-cover border-2 border-blue-500"
                />
              </div>
            )}
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Business Name</span>
                <span className="text-sm font-medium">{provider.displayName}</span>
              </div>
              {provider.bio && (
                <div>
                  <span className="text-sm text-zinc-600">Bio</span>
                  <p className="text-sm mt-1">{provider.bio}</p>
                </div>
              )}
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Verification Status</span>
                <StatusBadge status={provider.verificationStatus} />
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Availability</span>
                <StatusBadge status={provider.availabilityStatus} />
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Joined</span>
                <span className="text-sm font-medium">
                  {new Date(provider.createdAt).toLocaleDateString('vi-VN')}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Contact Information */}
        <Card>
          <CardHeader>
            <CardTitle>Contact Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <Phone className="h-4 w-4 text-zinc-600" />
                <span className="text-sm text-zinc-600">Phone</span>
              </div>
              <p className="font-mono text-sm font-medium ml-6">
                {provider.user?.phone || '—'}
              </p>
            </div>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <Mail className="h-4 w-4 text-zinc-600" />
                <span className="text-sm text-zinc-600">Email</span>
              </div>
              <p className="text-sm font-medium ml-6">
                {provider.user?.email || '—'}
              </p>
            </div>
            <div className="space-y-2">
              <span className="text-sm text-zinc-600">Full Name</span>
              <p className="text-sm font-medium">
                {provider.user?.profile?.fullName || '—'}
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Services Offered */}
        {provider.services && provider.services.length > 0 && (
          <Card className="md:col-span-2">
            <CardHeader>
              <CardTitle>Services Offered</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {provider.services.map((service) => (
                  <div key={service.id} className="p-3 rounded-lg bg-zinc-50">
                    <p className="font-medium">{service.service.name}</p>
                    <p className="text-sm text-zinc-600">
                      Base Price: {formatCurrency(service.basePrice)}
                    </p>
                    {service.description && (
                      <p className="text-xs text-zinc-500 mt-1">{service.description}</p>
                    )}
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
