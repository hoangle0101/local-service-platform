'use client';

import { useQuery } from '@tanstack/react-query';
import { useParams, useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import {
  ArrowLeft,
  DollarSign,
  User,
  Calendar,
} from 'lucide-react';
import { api } from '@/lib/api';
import { BookingDetail } from '@/types/booking';
import { ApiResponse } from '@/types/system';

export default function BookingDetailPage() {
  const params = useParams();
  const router = useRouter();
  const bookingId = params.id as string;

  const { data: response, isLoading } = useQuery({
    queryKey: ['admin-booking-detail', bookingId],
    queryFn: async () => {
      const res = await api.get<ApiResponse<BookingDetail>>(`/admin/bookings/${bookingId}`);
      return res.data;
    },
  });

  const booking = response?.data;

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

  if (!booking) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <p className="text-lg text-zinc-600">Booking not found</p>
          <Button onClick={() => router.push('/bookings')} className="mt-4">
            Back to Bookings
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => router.push('/bookings')}
        >
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Booking Details</h2>
          <p className="text-zinc-600">#{booking.id.slice(0, 8)}</p>
        </div>
        <div className="ml-auto">
          <StatusBadge status={booking.status} />
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Customer Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="h-4 w-4" />
              Customer
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center gap-3">
              {booking.customer?.profile?.avatarUrl && (
                <img
                  src={booking.customer.profile.avatarUrl}
                  alt="Customer"
                  className="h-12 w-12 rounded-full object-cover"
                />
              )}
              <div>
                <p className="font-medium">
                  {booking.customer?.profile?.fullName || 'N/A'}
                </p>
                <p className="text-sm text-zinc-600">{booking.customer?.phone}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Provider Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="h-4 w-4" />
              Provider
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center gap-3">
              {booking.provider?.avatarUrl && (
                <img
                  src={booking.provider.avatarUrl}
                  alt="Provider"
                  className="h-12 w-12 rounded-full object-cover"
                />
              )}
              <div>
                <p className="font-medium">{booking.provider?.businessName}</p>
                <p className="text-sm text-zinc-600">
                  {booking.provider?.user?.phone}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Service Information */}
        <Card>
          <CardHeader>
            <CardTitle>Service Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <p className="font-medium text-lg">{booking.service?.name}</p>
            {booking.service?.category && (
              <p className="text-sm text-zinc-600">{booking.service.category.name}</p>
            )}
          </CardContent>
        </Card>

        {/* Booking Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-4 w-4" />
              Booking Information
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex justify-between">
              <span className="text-sm text-zinc-600">Scheduled At</span>
              <span className="text-sm font-medium">
                {new Date(booking.scheduledAt).toLocaleString('vi-VN')}
              </span>
            </div>
            {booking.startedAt && (
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Started At</span>
                <span className="text-sm font-medium">
                  {new Date(booking.startedAt).toLocaleString('vi-VN')}
                </span>
              </div>
            )}
            {booking.completedAt && (
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Completed At</span>
                <span className="text-sm font-medium">
                  {new Date(booking.completedAt).toLocaleString('vi-VN')}
                </span>
              </div>
            )}
            {booking.cancelledAt && (
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Cancelled At</span>
                <span className="text-sm font-medium">
                  {new Date(booking.cancelledAt).toLocaleString('vi-VN')}
                </span>
              </div>
            )}
            <div className="flex justify-between">
              <span className="text-sm text-zinc-600">Created</span>
              <span className="text-sm font-medium">
                {new Date(booking.createdAt).toLocaleString('vi-VN')}
              </span>
            </div>
          </CardContent>
        </Card>

        {/* Payment Details */}
        <Card className="md:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <DollarSign className="h-4 w-4" />
              Payment Details
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <div className="grid grid-cols-2 gap-4">
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Service Price</span>
                <span className="text-sm font-medium">{formatCurrency(booking.actualPrice)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Status</span>
                <StatusBadge status={booking.payment?.status || 'pending'} />
              </div>
            </div>
            <div className="flex justify-between pt-2 border-t">
              <span className="font-medium text-lg">Total Amount</span>
              <span className="font-bold text-2xl text-green-600">{formatCurrency(booking.totalAmount)}</span>
            </div>
          </CardContent>
        </Card>

        {/* Notes */}
        {booking.notes && (
          <Card className="md:col-span-2">
            <CardHeader>
              <CardTitle>Notes</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-zinc-600">{booking.notes}</p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
