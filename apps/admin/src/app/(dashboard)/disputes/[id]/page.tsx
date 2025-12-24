'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useParams, useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { ArrowLeft, AlertTriangle } from 'lucide-react';
import { api } from '@/lib/api';
import { Dispute } from '@/types/dispute';
import { ApiResponse } from '@/types/system';
import { toast } from 'sonner';

export default function DisputeDetailPage() {
  const params = useParams();
  const router = useRouter();
  const disputeId = params.id as string;
  const [resolution, setResolution] = useState<'customer_favor' | 'provider_favor' | 'split'>('customer_favor');
  const [notes, setNotes] = useState('');
  const [refundAmount, setRefundAmount] = useState('0');
  const [isResolving, setIsResolving] = useState(false);

  const { data: response, isLoading, refetch } = useQuery({
    queryKey: ['admin-dispute-detail', disputeId],
    queryFn: async () => {
      const res = await api.get<ApiResponse<Dispute>>(`/admin/disputes/${disputeId}`);
      return res.data;
    },
  });

  const dispute = response?.data;

  // Format currency
  const formatCurrency = (amount: number | string) => {
    const numAmount = typeof amount === 'string' ? parseFloat(amount) : amount;
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(numAmount);
  };

  const handleResolve = async () => {
    setIsResolving(true);
    try {
      await api.post(`/admin/disputes/${disputeId}/resolve`, {
        resolution,
        refundAmount: parseFloat(refundAmount) || 0,
        notes: notes.trim() || undefined,
      });
      toast.success('Dispute resolved successfully');
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to resolve dispute');
    } finally {
      setIsResolving(false);
    }
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

  if (!dispute) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <p className="text-lg text-zinc-600">Dispute not found</p>
          <Button onClick={() => router.push('/disputes')} className="mt-4">
            Back to Disputes
          </Button>
        </div>
      </div>
    );
  }

  const canResolve = dispute.status === 'open' || dispute.status === 'under_review';

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => router.push('/disputes')}
        >
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div>
          <h2 className="text-3xl font-bold tracking-tight flex items-center gap-2">
            <AlertTriangle className="h-8 w-8 text-yellow-500" />
            Dispute Details
          </h2>
          <p className="text-zinc-600">#{dispute.id.slice(0, 8)}</p>
        </div>
        <div className="ml-auto">
          <StatusBadge status={dispute.status} />
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Dispute Information */}
        <Card>
          <CardHeader>
            <CardTitle>Dispute Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div>
              <span className="text-sm text-zinc-600">Booking ID</span>
              <p className="font-mono text-sm font-medium">
                #{dispute.bookingId.slice(0, 8)}
              </p>
              <p className="text-sm text-zinc-500">{dispute.booking?.service?.name}</p>
            </div>
            <div>
              <span className="text-sm text-zinc-600">Amount</span>
              <p className="font-medium">{formatCurrency(dispute.booking?.actualPrice || 0)}</p>
            </div>
            <div>
              <span className="text-sm text-zinc-600">Created</span>
              <p className="text-sm">{new Date(dispute.createdAt).toLocaleString('vi-VN')}</p>
            </div>
          </CardContent>
        </Card>

        {/* Reporter */}
        <Card>
          <CardHeader>
            <CardTitle>Reporter</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div>
              <span className="text-sm text-zinc-600">Name</span>
              <p className="font-medium">
                {dispute.reporter?.profile?.fullName || 'N/A'}
              </p>
            </div>
            <div>
              <span className="text-sm text-zinc-600">Phone</span>
              <p className="font-mono text-sm">{dispute.reporter?.phone}</p>
            </div>
          </CardContent>
        </Card>

        {/* Reason & Description */}
        <Card className="md:col-span-2">
          <CardHeader>
            <CardTitle>Dispute Reason</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div>
              <span className="text-sm font-medium text-zinc-600">Reason</span>
              <p className="mt-1">{dispute.reason}</p>
            </div>
            {dispute.description && (
              <div>
                <span className="text-sm font-medium text-zinc-600">Description</span>
                <p className="mt-1 text-zinc-600">{dispute.description}</p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Resolution */}
        {dispute.resolution ? (
          <Card className="md:col-span-2 bg-green-50 border-green-200">
            <CardHeader>
              <CardTitle className="text-green-600">Resolution</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <span className="text-sm text-green-900 font-medium">Resolution Type:</span>
                <p className="capitalize">{dispute.resolution.replace('_', ' ')}</p>
              </div>
              {dispute.refundAmount && (
                <div>
                  <span className="text-sm text-green-900 font-medium">Refund Amount:</span>
                  <p className="font-semibold">{formatCurrency(dispute.refundAmount)}</p>
                </div>
              )}
              {dispute.adminNotes && (
                <div>
                  <span className="text-sm text-green-900 font-medium">Admin Notes:</span>
                  <p className="text-sm text-green-900">{dispute.adminNotes}</p>
                </div>
              )}
              {dispute.resolvedAt && (
                <p className="text-xs text-green-700">
                  Resolved on {new Date(dispute.resolvedAt).toLocaleString('vi-VN')}
                </p>
              )}
            </CardContent>
          </Card>
        ) : canResolve ? (
          <Card className="md:col-span-2">
            <CardHeader>
              <CardTitle>Resolve Dispute</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label htmlFor="resolution">Resolution Type</Label>
                <Select value={resolution} onValueChange={(value: any) => setResolution(value)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="customer_favor">Customer Favor</SelectItem>
                    <SelectItem value="provider_favor">Provider Favor</SelectItem>
                    <SelectItem value="split">Split</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label htmlFor="refundAmount">Refund Amount (VND)</Label>
                <Input
                  id="refundAmount"
                  type="number"
                  value={refundAmount}
                  onChange={(e) => setRefundAmount(e.target.value)}
                  placeholder="0"
                  min="0"
                />
              </div>

              <div>
                <Label htmlFor="notes">Admin Notes</Label>
                <Textarea
                  id="notes"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="min-h-[100px]"
                  placeholder="Provide details about the resolution..."
                />
              </div>

              <Button
                onClick={handleResolve}
                disabled={isResolving}
                className="w-full"
              >
                {isResolving ? 'Resolving...' : 'Resolve Dispute'}
              </Button>
            </CardContent>
          </Card>
        ) : null}
      </div>
    </div>
  );
}
