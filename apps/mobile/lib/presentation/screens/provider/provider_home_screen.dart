import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/provider_datasource.dart';
import '../../widgets/minimalist_widgets.dart';

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
  bool _isAvailable = true;
  Map<String, dynamic>? _statistics;
  bool _isLoadingStats = true;
  String _verificationStatus = 'unverified';
  bool _isPhoneVerified = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);
    try {
      final stats = await ProviderDataSource().getStatistics();
      if (!mounted) return;
      setState(() {
        _statistics = stats;
        _isLoadingStats = false;
        _isAvailable = stats['isAvailable'] as bool? ?? true;
        _verificationStatus =
            stats['verificationStatus'] as String? ?? 'unverified';
        _isPhoneVerified = stats['isPhoneVerified'] as bool? ?? false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _toggleAvailability() async {
    try {
      await ProviderDataSource().updateAvailability(!_isAvailable);
      if (!mounted) return;
      setState(() => _isAvailable = !_isAvailable);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAvailable ? 'Đã bật nhận đơn' : 'Đã tắt nhận đơn'),
          backgroundColor: _isAvailable ? AppColors.success : AppColors.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerified = _verificationStatus == 'verified';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoadingStats
          ? const Center(child: CircularProgressIndicator())
          : !isVerified || !_isPhoneVerified
              ? _buildVerificationRequiredScreen()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadStatistics,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      _buildSliverAppBar(),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAvailabilityCard(),
                              const SizedBox(height: 32),
                              _buildSectionLabel('THỐNG KÊ'),
                              const SizedBox(height: 16),
                              _buildStatsGrid(),
                              const SizedBox(height: 32),
                              _buildSectionLabel('TRUY CẬP NHANH'),
                              const SizedBox(height: 16),
                              _buildQuickActions(),
                              const SizedBox(height: 32),
                              _buildSectionLabel('HOẠT ĐỘNG GẦN ĐÂY'),
                              const SizedBox(height: 16),
                              _buildRecentActivity(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chào bạn quay lại,',
                        style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Dashboard',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                                fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/user/home'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.shelf,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        size: 22, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.textTertiary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return MinCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_isAvailable ? AppColors.success : AppColors.warning)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isAvailable ? Icons.bolt_rounded : Icons.bolt_outlined,
              color: _isAvailable ? AppColors.success : AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable ? 'Đang nhận đơn' : 'Đang tạm nghỉ',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary),
                ),
                Text(
                  _isAvailable
                      ? 'Khách hàng có thể tìm thấy bạn'
                      : 'Bạn sẽ không xuất hiện trong tìm kiếm',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isAvailable,
            onChanged: (v) => _toggleAvailability(),
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalEarnings = _safeDouble(_statistics?['totalEarnings']);
    final completedJobs = _safeInt(_statistics?['completedJobs']);
    final rating = _safeDouble(_statistics?['rating']);
    final currencyFormat =
        NumberFormat.compactCurrency(locale: 'vi_VN', symbol: '₫');

    return Row(
      children: [
        Expanded(
          child: MinCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('THU NHẬP',
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(currencyFormat.format(totalEarnings),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MinCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HOÀN TẤT',
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('$completedJobs jobs',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MinCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ĐÁNH GIÁ',
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning)),
                    const Icon(Icons.star_rounded,
                        color: AppColors.warning, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionItem(Icons.work_history_rounded, 'Đơn hàng',
            () => context.push('/provider/bookings')),
        _buildActionItem(Icons.build_circle_rounded, 'Dịch vụ',
            () => context.push('/provider/services')),
        _buildActionItem(Icons.star_rounded, 'Phản hồi',
            () => context.push('/provider/my-reviews')),
        _buildActionItem(Icons.settings_rounded, 'Cài đặt',
            () => context.push('/provider/profile')),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MinCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return MinCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: AppColors.shelf, shape: BoxShape.circle),
              child: const Icon(Icons.history_rounded,
                  color: AppColors.textTertiary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Chưa có hoạt động',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Các việc bạn làm sẽ hiện ở đây.',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationRequiredScreen() {
    final bool isRejected = _verificationStatus == 'rejected';

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                    color: AppColors.shelf, shape: BoxShape.circle),
                child: Icon(
                  !_isPhoneVerified
                      ? Icons.phone_iphone_rounded
                      : isRejected
                          ? Icons.error_outline_rounded
                          : Icons.verified_user_rounded,
                  size: 64,
                  color: isRejected ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                !_isPhoneVerified
                    ? 'Cần xác thực SĐT'
                    : isRejected
                        ? 'Hồ sơ bị từ chối'
                        : 'Đang chờ duyệt',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                !_isPhoneVerified
                    ? 'Hãy xác thực số điện thoại để bắt đầu nhận đơn khách hàng nhé.'
                    : isRejected
                        ? 'Rất tiếc hồ sơ của bạn chưa phù hợp. Liên hệ hỗ trợ để biết thêm chi tiết.'
                        : 'Hồ sơ đang được xem xét. Quá trình thường mất 24h.',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (!_isPhoneVerified)
                MinButton(text: 'Xác thực ngay', onPressed: () {}),
              const SizedBox(height: 16),
              MinButton(
                  text: 'Trở về trang khách',
                  isPrimary: false,
                  onPressed: () => context.go('/user/home')),
            ],
          ),
        ),
      ),
    );
  }
}
