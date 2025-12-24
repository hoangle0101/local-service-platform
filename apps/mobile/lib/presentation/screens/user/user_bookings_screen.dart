import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/bookings_datasource.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/review_dialog.dart';
import '../../widgets/minimalist_widgets.dart';
import '../../widgets/booking_offers_dialog.dart';
import '../booking/invoice_screen.dart';

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

  void _showOffersDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => BookingOffersDialog(
        bookingId: bookingId,
        onProviderSelected: _refreshBookings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBookings,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: BlocBuilder<BookingsBloc, BookingsState>(
            builder: (context, state) {
              int pendingCount = 0;
              int acceptedCount = 0;
              int completedCount = 0;
              int cancelledCount = 0;

              if (state is BookingsLoaded) {
                final bookings = state.bookings;
                pendingCount =
                    bookings.where((b) => b.status == 'pending').length;
                acceptedCount = bookings
                    .where((b) =>
                        b.status == 'accepted' ||
                        b.status == 'confirmed' ||
                        b.status == 'in_progress' ||
                        b.status == 'pending_completion' ||
                        b.status == 'pending_payment')
                    .length;
                completedCount =
                    bookings.where((b) => b.status == 'completed').length;
                cancelledCount = bookings
                    .where((b) =>
                        b.status == 'cancelled' || b.status == 'disputed')
                    .length;
              }

              return TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primaryDark,
                isScrollable: true,
                tabs: [
                  Tab(
                      text:
                          'Pending${pendingCount > 0 ? " ($pendingCount)" : ""}'),
                  Tab(
                      text:
                          'Accepted${acceptedCount > 0 ? " ($acceptedCount)" : ""}'),
                  Tab(
                      text:
                          'Completed${completedCount > 0 ? " ($completedCount)" : ""}'),
                  Tab(
                      text:
                          'Cancelled${cancelledCount > 0 ? " ($cancelledCount)" : ""}'),
                ],
              );
            },
          ),
        ),
      ),
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
      expandedHeight: 160,
      backgroundColor: AppColors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Lịch đặt của tôi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(
                bottom: BorderSide(color: AppColors.divider.withOpacity(0.5))),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 3, color: AppColors.primary),
              insets: EdgeInsets.symmetric(horizontal: 0),
            ),
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.2),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              _buildTab('Chờ xác nhận', pendingCount),
              _buildTab('Đã nhận', acceptedCount),
              _buildTab('Hoàn thành', completedCount),
              _buildTab('Đã hủy', cancelledCount),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
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
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: AppColors.shelf,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  size: 48, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 32),
            const Text(
              'Chưa có lịch đặt nào',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tại mục này hiện chưa có thông tin gì.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
    final price = double.tryParse(booking.estimatedPrice ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMinStatusBadge(booking.status),
                    Text(
                      '#${booking.code}',
                      style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  booking.serviceName ?? 'Dịch vụ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                _buildInfoItem(
                    Icons.calendar_today_rounded,
                    booking.scheduledAt != null
                        ? dateFormat.format(booking.scheduledAt!)
                        : 'Chưa xác định'),
                const SizedBox(height: 10),
                _buildInfoItem(Icons.location_on_rounded,
                    booking.addressText ?? 'Địa chỉ không xác định'),
                if (booking.providerName != null) ...[
                  const SizedBox(height: 10),
                  _buildInfoItem(
                      Icons.person_rounded, 'Đối tác: ${booking.providerName}'),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.shelf.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border(
                  top: BorderSide(color: AppColors.divider.withOpacity(0.5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng thanh toán',
                        style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2)),
                    Text(
                      currencyFormat.format(price).replaceAll(',00', ''),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16),
                    ),
                  ],
                ),
                _buildActionButtons(booking),
              ],
            ),
          ),
        ],
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
      case 'pending_payment':
        color = Colors.orange;
        label = 'CHỜ THANH TOÁN';
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
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(booking.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: View offers
              },
              child: const Text('View Offers'),
            ),
          ),
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
    } else if (status == 'pending_payment') {
      // Customer needs to pay
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InvoiceScreen(bookingId: booking.id),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.payment),
          label: const Text('Thanh toán'),
        ),
      );
    } else if (status == 'completed') {
      // Check if already reviewed
      if (booking.hasReview) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'Đã đánh giá ${booking.review?.rating ?? 0}★',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      // Not reviewed yet - show review button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showReviewDialog(
            booking.id,
            serviceName: booking.serviceName,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.star_rounded),
          label: const Text(
            'Đánh giá dịch vụ',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else if (status == 'cancelled' || status == 'disputed') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            // TODO: Rebook
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Book Again'),
        ),
      );
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

  Future<void> _submitDispute(String bookingId, String reason) async {
    try {
      final datasource = BookingsDataSource();
      await datasource.disputeBooking(bookingId, reason);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi khiếu nại. Chúng tôi sẽ liên hệ với bạn sớm.'),
          backgroundColor: Colors.orange,
        ),
      );

      _refreshBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
