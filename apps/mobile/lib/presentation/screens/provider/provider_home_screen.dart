import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/provider_datasource.dart';

// Safe parsing helpers
int _safeInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double _safeDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedIndex = 0;
  bool _isAvailable = true;
  Map<String, dynamic>? _statistics;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await ProviderDataSource().getStatistics();
      setState(() {
        _statistics = stats;
        _isLoadingStats = false;
        _isAvailable = stats['isAvailable'] as bool? ?? true;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleAvailability() async {
    try {
      await ProviderDataSource().updateAvailability(!_isAvailable);
      setState(() => _isAvailable = !_isAvailable);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isAvailable ? 'Đã bật nhận đơn' : 'Đã tắt nhận đơn'),
            backgroundColor: _isAvailable ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        context.push('/provider/bookings');
        break;
      case 2:
        context.push('/provider/services');
        break;
      case 3:
        context.push('/provider/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: CustomScrollView(
          slivers: [
            // Modern Header with Gradient
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            // Stats Cards
            SliverToBoxAdapter(
              child: _buildStatsSection(),
            ),
            // Quick Actions
            SliverToBoxAdapter(
              child: _buildQuickActions(),
            ),
            // Recent Activity
            SliverToBoxAdapter(
              child: _buildRecentSection(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withBlue(200),
            AppColors.primary.withGreen(120),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.handyman,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào!',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14),
                          ),
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Switch to Customer button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Navigate to customer home
                            context.go('/user/home');
                          },
                          tooltip: 'Chuyển sang Customer',
                          icon: const Icon(Icons.person_outline,
                              color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {},
                        icon: Stack(
                          children: [
                            const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 28),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Availability Toggle Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isAvailable ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isAvailable ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAvailable ? 'Đang hoạt động' : 'Tạm nghỉ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _isAvailable
                                ? 'Bạn có thể nhận đơn mới'
                                : 'Bạn sẽ không nhận đơn mới',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 1.1,
                      child: Switch(
                        value: _isAvailable,
                        onChanged: (_) => _toggleAvailability(),
                        activeColor: Colors.green,
                        activeTrackColor: Colors.green.shade200,
                        inactiveThumbColor: Colors.orange,
                        inactiveTrackColor: Colors.orange.shade200,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final totalEarnings = _safeDouble(_statistics?['totalEarnings']);
    final completedJobs = _safeInt(_statistics?['completedJobs']);
    final pendingJobs = _safeInt(_statistics?['pendingJobs']);
    final rating = _safeDouble(_statistics?['rating']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_isLoadingStats)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.green,
                    bgColor: Colors.green.shade50,
                    title: 'Doanh thu',
                    value: _formatMoney(totalEarnings),
                    subtitle: 'VND',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle,
                    iconColor: Colors.blue,
                    bgColor: Colors.blue.shade50,
                    title: 'Hoàn thành',
                    value: completedJobs.toString(),
                    subtitle: 'đơn hàng',
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.pending_actions,
                  iconColor: Colors.orange,
                  bgColor: Colors.orange.shade50,
                  title: 'Đang chờ',
                  value: pendingJobs.toString(),
                  subtitle: 'đơn hàng',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  bgColor: Colors.amber.shade50,
                  title: 'Đánh giá',
                  value: rating.toStringAsFixed(1),
                  subtitle: '/ 5.0 sao',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Truy cập nhanh',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.work_history,
                  title: 'Công việc',
                  subtitle: 'Xem đơn hàng',
                  color: AppColors.primary,
                  onTap: () => context.push('/provider/bookings'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.build_circle,
                  title: 'Dịch vụ',
                  subtitle: 'Quản lý dịch vụ',
                  color: Colors.teal,
                  onTap: () => context.push('/provider/services'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.bar_chart,
                  title: 'Báo cáo',
                  subtitle: 'Xem thống kê',
                  color: Colors.purple,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.person_outline,
                  title: 'Hồ sơ',
                  subtitle: 'Cập nhật thông tin',
                  color: Colors.deepOrange,
                  onTap: () => context.push('/provider/profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hoạt động gần đây',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.push('/provider/bookings'),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Chưa có hoạt động nào',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.push('/provider/bookings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Xem công việc'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                isSelected: _selectedIndex == 0,
                onTap: () => _onNavItemTapped(0),
              ),
              _NavItem(
                icon: Icons.work_outline,
                label: 'Công việc',
                isSelected: _selectedIndex == 1,
                onTap: () => _onNavItemTapped(1),
              ),
              _NavItem(
                icon: Icons.build_circle_outlined,
                label: 'Dịch vụ',
                isSelected: _selectedIndex == 2,
                onTap: () => _onNavItemTapped(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Hồ sơ',
                isSelected: _selectedIndex == 3,
                onTap: () => _onNavItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}

// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// Bottom Nav Item Widget
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
