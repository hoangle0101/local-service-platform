import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/bookings_datasource.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/minimalist_widgets.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingsDataSource _bookingsDataSource = BookingsDataSource();

  List<Booking> _myRequests = [];
  List<Booking> _globalRequests = [];
  bool _isLoadingMyRequests = false;
  bool _isLoadingGlobalRequests = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    _loadMyRequests();
    _loadGlobalRequests();
    context.read<BookingsBloc>().add(const LoadProviderBookings());
  }

  Future<void> _loadMyRequests() async {
    if (!mounted) return;
    setState(() => _isLoadingMyRequests = true);
    try {
      final requests = await _bookingsDataSource.getProviderRequests();
      if (mounted) {
        setState(() {
          _myRequests = requests;
          _isLoadingMyRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMyRequests = false);
      }
    }
  }

  Future<void> _loadGlobalRequests() async {
    if (!mounted) return;
    setState(() => _isLoadingGlobalRequests = true);
    try {
      final requests = await _bookingsDataSource.getGlobalRequests();
      if (mounted) {
        setState(() {
          _globalRequests = requests;
          _isLoadingGlobalRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGlobalRequests = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<BookingsBloc, BookingsState>(
        listener: (context, state) {
          if (state is BookingActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
            _loadAllData();
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildSliverAppBar(context),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsTab(isGlobal: false),
                    _buildRequestsTab(isGlobal: true),
                    _buildInProgressTab(state),
                    _buildCompletedTab(state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 240,
      backgroundColor: AppColors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: EdgeInsets.fromLTRB(24, topPadding + 40, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Công việc của tôi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Theo dõi và quản lý các yêu cầu của khách hàng gửi đến bạn',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(
                bottom: BorderSide(
                    color: AppColors.divider.withOpacity(0.3), width: 1)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.only(
                left: 8), // Aligns with the 24px container padding
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primary, width: 4),
              insets: EdgeInsets.zero,
            ),
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              _buildTab('Yêu cầu', _myRequests.length),
              _buildTab('Xa hơn', _globalRequests.length),
              const Tab(text: 'Đang làm'),
              const Tab(text: 'Hoàn tất'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestsTab({required bool isGlobal}) {
    final isLoading =
        isGlobal ? _isLoadingGlobalRequests : _isLoadingMyRequests;
    final requests = isGlobal ? _globalRequests : _myRequests;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return _buildEmptyState(
        isGlobal ? 'Không có yêu cầu xa' : 'Chưa có yêu cầu mới',
        isGlobal
            ? 'Chúng tôi sẽ báo khi có khách hàng cần bạn.'
            : 'Hãy kiên nhẫn, công việc sẽ sớm đến.',
        Icons.work_outline_rounded,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: isGlobal ? _loadGlobalRequests : _loadMyRequests,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestMinCard(requests[index], isGlobal: isGlobal);
        },
      ),
    );
  }

  Widget _buildInProgressTab(BookingsState state) {
    if (state is BookingsLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is BookingsLoaded) {
      // Build full avatar URL
      final inProgress = state.bookings
          .where((b) =>
              b.status == 'accepted' ||
              b.status == 'confirmed' ||
              b.status == 'in_progress' ||
              b.status == 'pending_completion')
          .toList();

      if (inProgress.isEmpty) {
        return _buildEmptyState(
            'Trống',
            'Bạn chưa có công việc đang thực hiện.',
            Icons.work_history_rounded);
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async =>
            context.read<BookingsBloc>().add(const LoadProviderBookings()),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          itemCount: inProgress.length,
          itemBuilder: (context, index) {
            return _buildBookingMinCard(inProgress[index]);
          },
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildCompletedTab(BookingsState state) {
    if (state is BookingsLoaded) {
      final completed =
          state.bookings.where((b) => b.status == 'completed').toList();
      if (completed.isEmpty) {
        return _buildEmptyState('Chưa xong việc nào',
            'Hãy bắt đầu nhận việc ngay.', Icons.check_circle_outline_rounded);
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        itemCount: completed.length,
        itemBuilder: (context, index) {
          return _buildBookingMinCard(completed[index]);
        },
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildRequestMinCard(Booking booking, {required bool isGlobal}) {
    final distanceKm = (booking.distance ?? 0) / 1000;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: MinCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName ?? 'Dịch vụ',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 18),
                  ),
                ),
                MinBadge(
                  label: '${distanceKm.toStringAsFixed(1)} km',
                  color: isGlobal
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  textColor: isGlobal ? AppColors.warning : AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Khách hàng: ${booking.customerName ?? "N/A"}',
              style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const Divider(height: 32, color: AppColors.divider),
            _buildInfoRow(
                Icons.location_on_rounded, booking.addressText ?? 'N/A'),
            const SizedBox(height: 10),
            _buildInfoRow(
                Icons.access_time_filled_rounded,
                booking.scheduledAt != null
                    ? DateFormat('HH:mm - dd/MM/yyyy')
                        .format(booking.scheduledAt!)
                    : 'Chưa định'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thu nhập ước tính',
                        style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    Text(
                      currencyFormat.format(
                          double.tryParse(booking.estimatedPrice ?? '0') ?? 0),
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                  ],
                ),
                MinButton(
                  text: 'Nhận việc',
                  onPressed: () => _acceptRequest(booking),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingMinCard(Booking booking) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: MinCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName ?? 'Dịch vụ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildMinStatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Khách hàng: ${booking.customerName ?? "N/A"}',
              style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const Divider(height: 32, color: AppColors.divider),
            _buildInfoRow(
                Icons.location_on_rounded, booking.addressText ?? 'N/A'),
            const SizedBox(height: 10),
            _buildInfoRow(
                Icons.access_time_filled_rounded,
                booking.scheduledAt != null
                    ? DateFormat('HH:mm - dd/MM/yyyy')
                        .format(booking.scheduledAt!)
                    : 'N/A'),
            const SizedBox(height: 20),
            _buildBookingActions(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMinStatusBadge(String? status) {
    Color color = AppColors.textTertiary;
    String label = status?.toUpperCase() ?? 'N/A';

    switch (status) {
      case 'confirmed':
      case 'accepted':
        color = AppColors.accent;
        label = 'Đã nhận';
        break;
      case 'in_progress':
        color = AppColors.primary;
        label = 'Đang làm';
        break;
      case 'pending_completion':
        color = AppColors.warning;
        label = 'Chờ khách xác nhận';
        break;
      case 'completed':
        color = AppColors.success;
        label = 'Hoàn thành';
        break;
    }

    return MinBadge(
      label: label,
      color: color.withOpacity(0.1),
      textColor: color,
    );
  }

  Widget _buildBookingActions(Booking booking) {
    if (booking.status == 'accepted' || booking.status == 'confirmed') {
      return MinButton(
        text: 'Bắt đầu ngay',
        isFullWidth: true,
        onPressed: () => _startService(booking),
        icon: Icons.play_arrow_rounded,
      );
    }
    if (booking.status == 'in_progress') {
      return MinButton(
        text: 'Hoàn thành công việc',
        isFullWidth: true,
        onPressed: () => _completeService(booking),
        icon: Icons.check_circle_rounded,
      );
    }
    if (booking.status == 'completed' && booking.review != null) {
      return MinButton(
        text: 'Xem đánh giá',
        isPrimary: false,
        isFullWidth: true,
        onPressed: () => _showCustomerReviewDialog(booking.review!,
            customerName: booking.customerName),
        icon: Icons.star_rounded,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.shelf.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 64, color: AppColors.textTertiary.withOpacity(0.3)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(Booking booking) async {
    try {
      final bookingId = int.tryParse(booking.id) ?? 0;
      await _bookingsDataSource.acceptBookingRequest(bookingId);
      _loadAllData();
    } catch (e) {
      // Handled by snackbar in bloc if applicable, or add a local one
    }
  }

  Future<void> _startService(Booking booking) async {
    try {
      await _bookingsDataSource.startService(booking.id);
      _loadAllData();
    } catch (e) {}
  }

  Future<void> _completeService(Booking booking) async {
    try {
      await _bookingsDataSource.completeService(booking.id);
      _loadAllData();
    } catch (e) {}
  }

  void _showCustomerReviewDialog(BookingReview review, {String? customerName}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Đánh giá từ ${customerName ?? "khách"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (index) => Icon(
                        index < review.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.warning,
                        size: 32,
                      )),
            ),
            const SizedBox(height: 16),
            Text(review.comment ?? 'Không có nhận xét.',
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng')),
        ],
      ),
    );
  }
}
