'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatsCard } from '@/components/ui/stats-card';
import { StatusBadge } from '@/components/ui/status-badge';
import {
  Users,
  Briefcase,
  DollarSign,
  Activity,
  AlertTriangle,
  TrendingUp,
  CheckCircle,
  ShieldCheck,
} from 'lucide-react';
import { motion } from 'framer-motion';
import { useQuery } from '@tanstack/react-query';
import { api } from '@/lib/api';
import { DashboardStats, ApiResponse } from '@/types/system';

const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1
    }
  }
};

const item = {
  hidden: { y: 20, opacity: 0 },
  show: { y: 0, opacity: 1 }
};

export default function DashboardPage() {
  // Get current user info
  const { data: user } = useQuery({
    queryKey: ['me'],
    queryFn: async () => {
      const response = await api.get<ApiResponse<any>>('/users/me');
      return response.data.data;
    },
  });

  // Get dashboard stats
  const { data: statsResponse, isLoading } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const response = await api.get<ApiResponse<DashboardStats>>('/admin/dashboard');
      return response.data;
    },
    refetchInterval: 30000, // Refresh every 30s
  });

  const stats = statsResponse?.data;

  if (isLoading) {
    return (
      <div className="space-y-8">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Dashboard</h2>
          <p className="text-zinc-600">Welcome back, {user?.profile?.fullName || 'Admin'}</p>
        </div>
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-32 rounded-lg bg-zinc-100 animate-pulse" />
          ))}
        </div>
      </div>
    );
  }

  // Format currency
  const formatCurrency = (amount: number | string) => {
    const numAmount = typeof amount === 'string' ? parseFloat(amount) : amount;
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(numAmount);
  };

  const statsCards = [
    {
      title: 'Total Revenue',
      value: formatCurrency(stats?.financials.totalRevenue || 0),
      change: 'Total earnings',
      icon: DollarSign,
      gradient: 'bg-gradient-to-br from-yellow-50 to-orange-50',
      iconColor: 'text-orange-500',
    },
    {
      title: 'Active Users',
      value: stats?.overview.totalUsers.toString() || '0',
      change: 'Total registered users',
      icon: Users,
      gradient: 'bg-gradient-to-br from-blue-50 to-indigo-50',
      iconColor: 'text-blue-500',
    },
    {
      title: 'Active Providers',
      value: stats?.overview.activeProviders.toString() || '0',
      change: 'Verified providers',
      icon: Briefcase,
      gradient: 'bg-gradient-to-br from-green-50 to-emerald-50',
      iconColor: 'text-green-500',
    },
    {
      title: 'Open Disputes',
      value: stats?.overview.openDisputes.toString() || '0',
      change: 'Requires attention',
      icon: AlertTriangle,
      gradient: 'bg-gradient-to-br from-red-50 to-rose-50',
      iconColor: 'text-red-500',
    },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">Dashboard</h2>
        <p className="text-zinc-600">Welcome back, {user?.profile?.fullName || 'Admin'}</p>
      </div>

      <motion.div 
        variants={container}
        initial="hidden"
        animate="show"
        className="grid gap-4 md:grid-cols-2 lg:grid-cols-4"
      >
        {statsCards.map((stat, index) => (
          <motion.div key={index} variants={item}>
            <StatsCard {...stat} />
          </motion.div>
        ))}
      </motion.div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <StatsCard
          title="Total Bookings"
          value={stats?.overview.totalBookings.toString() || '0'}
          icon={Activity}
          change="All time bookings"
          gradient="bg-gradient-to-br from-purple-50 to-pink-50"
          iconColor="text-purple-500"
        />
        <StatsCard
          title="Completed Bookings"
          value={stats?.overview.completedBookings.toString() || '0'}
          icon={CheckCircle}
          change={`Completion rate: ${stats?.overview.completionRate || '0%'}`}
          gradient="bg-gradient-to-br from-teal-50 to-cyan-50"
          iconColor="text-teal-500"
        />
        <StatsCard
          title="Avg. Booking Value"
          value={formatCurrency(stats?.financials.avgBookingValue || 0)}
          icon={TrendingUp}
          change="Average per booking"
          gradient="bg-gradient-to-br from-cyan-50 to-sky-50"
          iconColor="text-cyan-500"
        />
        <StatsCard
          title="Dispute Resolution"
          value={stats?.overview.disputeResolutionRate || '0%'}
          icon={ShieldCheck}
          change="Resolution rate"
          gradient="bg-gradient-to-br from-indigo-50 to-violet-50"
          iconColor="text-indigo-500"
        />
      </div>

      <div className="grid gap-4 md:grid-cols-1">
        <Card className="col-span-1">
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
          </CardHeader>
          <CardContent>
            {stats?.recentActivity && stats.recentActivity.length > 0 ? (
              <div className="space-y-4">
                {stats.recentActivity.map((booking) => (
                  <div key={booking.id.toString()} className="flex items-center justify-between p-4 rounded-lg bg-zinc-50">
                    <div className="space-y-1">
                      <p className="text-sm font-medium">Booking #{booking.id.toString().slice(0, 8)}</p>
                      <p className="text-sm text-zinc-600">Service: {booking.service}</p>
                      <p className="text-xs text-zinc-500">{new Date(booking.createdAt).toLocaleString('vi-VN')}</p>
                    </div>
                    <div className="text-right space-y-1">
                      <p className="text-sm font-medium">{formatCurrency(booking.price)}</p>
                      <StatusBadge status={booking.status} />
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="flex items-center justify-center h-[200px] text-zinc-600">
                No recent activity
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
