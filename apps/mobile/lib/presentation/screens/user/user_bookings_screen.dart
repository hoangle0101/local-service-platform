import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/bookings_datasource.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/review_dialog.dart';
import '../../widgets/minimalist_widgets.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingsBloc>().add(const LoadBookings());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshBookings() {
    context.read<BookingsBloc>().add(const LoadBookings());
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
          } else if (state is BookingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildSliverAppBar(context, state),
              SliverFillRemaining(
                child: _buildBody(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, BookingsState state) {
    int pendingCount = 0;
    int acceptedCount = 0;
    int completedCount = 0;
    int cancelledCount = 0;

    if (state is BookingsLoaded) {
      final bookings = state.bookings;
      pendingCount = bookings.where((b) => b.status == 'pending').length;
      acceptedCount = bookings
          .where((b) =>
              b.status == 'accepted' ||
              b.status == 'confirmed' ||
              b.status == 'in_progress' ||
              b.status == 'pending_completion')
          .length;
      completedCount = bookings.where((b) => b.status == 'completed').length;
      cancelledCount = bookings
          .where((b) => b.status == 'cancelled' || b.status == 'disputed')
          .length;
    }

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 140,
      backgroundColor: AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.shelf,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: _refreshBookings,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.shelf,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Lịch đặt của tôi',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: 'Chờ x/n${pendingCount > 0 ? " ($pendingCount)" : ""}'),
              Tab(
                  text:
                      'Đã nhận${acceptedCount > 0 ? " ($acceptedCount)" : ""}'),
              Tab(
                  text:
                      'Hoàn thành${completedCount > 0 ? " ($completedCount)" : ""}'),
              Tab(
                  text:
                      'Đã hủy${cancelledCount > 0 ? " ($cancelledCount)" : ""}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BookingsState state) {
    if (state is BookingsLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is BookingsLoaded) {
      final bookings = state.bookings;
      return TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(
              bookings.where((b) => b.status == 'pending').toList()),
          _buildBookingsList(bookings
              .where((b) =>
                  b.status == 'accepted' ||
                  b.status == 'confirmed' ||
                  b.status == 'in_progress' ||
                  b.status == 'pending_completion')
              .toList()),
          _buildBookingsList(
              bookings.where((b) => b.status == 'completed').toList()),
          _buildBookingsList(bookings
              .where((b) => b.status == 'cancelled' || b.status == 'disputed')
              .toList()),
        ],
      );
    } else if (state is BookingsError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Không thể tải lịch đặt',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              MinButton(text: 'Thử lại', onPressed: _refreshBookings),
            ],
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.shelf,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  size: 40, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 20),
            Text(
              'Trống',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn chưa có lịch đặt nào ở mục này.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => _refreshBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingMinCard(bookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingMinCard(Booking booking) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('EEE, dd MMM yyyy • HH:mm');

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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildMinStatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Mã: ${booking.code}',
              style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
                Icons.access_time_rounded,
                booking.scheduledAt != null
                    ? dateFormat.format(booking.scheduledAt!)
                    : 'Chưa xác định'),
            const SizedBox(height: 10),
            _buildInfoItem(
                Icons.location_on_rounded, booking.addressText ?? 'N/A'),
            if (booking.providerName != null) ...[
              const SizedBox(height: 10),
              _buildInfoItem(
                  Icons.person_rounded, 'Đối tác: ${booking.providerName}'),
            ],
            const Divider(height: 32, color: AppColors.divider),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng thanh toán',
                        style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    Text(
                      currencyFormat.format(
                          double.tryParse(booking.estimatedPrice ?? '0') ?? 0),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                  ],
                ),
                _buildActionButtons(booking),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
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

  Widget _buildMinStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        color = AppColors.warning;
        label = 'Đang chờ';
        break;
      case 'confirmed':
      case 'accepted':
        color = AppColors.accent;
        label = 'Đã nhận';
        break;
      case 'in_progress':
        color = AppColors.primary;
        label = 'Đang thực hiện';
        break;
      case 'pending_completion':
        color = AppColors.success;
        label = 'Hoàn tất?';
        break;
      case 'completed':
        color = AppColors.success;
        label = 'Xây xong';
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'Đã hủy';
        break;
      case 'disputed':
        color = AppColors.error;
        label = 'Khiếu nại';
        break;
      default:
        color = AppColors.textTertiary;
        label = status.toUpperCase();
    }

    return MinBadge(
      label: label,
      color: color.withOpacity(0.1),
      textColor: color,
    );
  }

  Widget _buildActionButtons(Booking booking) {
    final status = booking.status.toLowerCase();

    if (status == 'pending') {
      return Row(
        children: [
          _buildSmallButton('Hủy', () => _showCancelDialog(booking.id),
              isError: true),
        ],
      );
    } else if (status == 'pending_completion') {
      return Row(
        children: [
          _buildSmallButton('Khiếu nại', () => _showDisputeDialog(booking.id),
              isError: true),
          const SizedBox(width: 8),
          _buildSmallButton('Xác nhận', () => _confirmCompletion(booking.id),
              isPrimary: true),
        ],
      );
    } else if (status == 'completed' && !booking.hasReview) {
      return _buildSmallButton('Đánh giá',
          () => _showReviewDialog(booking.id, serviceName: booking.serviceName),
          isPrimary: true);
    }

    return const SizedBox.shrink();
  }

  Widget _buildSmallButton(String text, VoidCallback onTap,
      {bool isPrimary = false, bool isError = false}) {
    Color bgColor = isPrimary
        ? AppColors.primary
        : (isError ? AppColors.error.withOpacity(0.1) : AppColors.shelf);
    Color textColor = isPrimary
        ? Colors.white
        : (isError ? AppColors.error : AppColors.textPrimary);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: isPrimary
              ? null
              : Border.all(
                  color: isError
                      ? AppColors.error.withOpacity(0.2)
                      : AppColors.divider),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hủy lịch đặt'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch đặt này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Không',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          MinButton(
            text: 'Có, Hủy bỏ',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<BookingsBloc>().add(CancelBooking(bookingId));
            },
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(String bookingId, {String? serviceName}) {
    ReviewDialog.show(
      context,
      bookingId: bookingId,
      serviceName: serviceName,
      onSubmit: (rating, comment) async {
        await BookingsDataSource().reviewBooking(bookingId, rating, comment);
        if (mounted) _refreshBookings();
      },
    );
  }

  Future<void> _confirmCompletion(String bookingId) async {
    try {
      await BookingsDataSource().confirmCompletion(bookingId);
      if (mounted) {
        _refreshBookings();
        _showReviewDialog(bookingId);
      }
    } catch (e) {
      // Error handled by bloc listener
    }
  }

  void _showDisputeDialog(String bookingId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Khiếu nại dịch vụ'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'Nhập lý do khiếu nại...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          MinButton(
            text: 'Gửi yêu cầu',
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await BookingsDataSource()
                  .disputeBooking(bookingId, reasonController.text);
              if (mounted) _refreshBookings();
            },
          ),
        ],
      ),
    );
  }
}
