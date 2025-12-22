import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/bookings_datasource.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/review_dialog.dart';

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
    // Load bookings when screen initializes
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
                        b.status == 'pending_completion')
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
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is BookingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          print('[UserBookingsScreen] Current state: ${state.runtimeType}');
          if (state is BookingsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BookingsLoaded) {
            final bookings = state.bookings;
            print(
                '[UserBookingsScreen] BookingsLoaded with ${bookings.length} bookings');
            for (var b in bookings) {
              print(
                  '[UserBookingsScreen] Booking: ${b.code} - status: ${b.status}');
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(
                  bookings.where((b) => b.status == 'pending').toList(),
                ),
                _buildBookingsList(
                  bookings
                      .where((b) =>
                          b.status == 'accepted' ||
                          b.status == 'confirmed' ||
                          b.status == 'in_progress' ||
                          b.status == 'pending_completion')
                      .toList(),
                ),
                _buildBookingsList(
                  bookings.where((b) => b.status == 'completed').toList(),
                ),
                _buildBookingsList(
                  bookings
                      .where((b) =>
                          b.status == 'cancelled' || b.status == 'disputed')
                      .toList(),
                ),
              ],
            );
          } else if (state is BookingsError) {
            print('[UserBookingsScreen] BookingsError: ${state.message}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load bookings',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _refreshBookings,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          // Initial state - trigger load
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your bookings will appear here',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName ?? 'Dịch vụ',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${booking.code}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(booking.status),
              ],
            ),

            const Divider(height: 24),

            // Details
            _buildInfoRow(
              Icons.calendar_today_outlined,
              booking.scheduledAt != null
                  ? DateFormat('EEE, dd MMM yyyy • HH:mm')
                      .format(booking.scheduledAt!)
                  : 'Chưa xác định',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
                Icons.location_on_outlined, booking.addressText ?? ''),

            if (booking.estimatedPrice != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.attach_money,
                NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                    .format(double.tryParse(booking.estimatedPrice!) ?? 0),
              ),
            ],

            if (booking.providerName != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                  Icons.person_outline, 'Provider: ${booking.providerName}'),
            ],

            const SizedBox(height: 16),

            // Actions
            _buildActionButtons(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        displayStatus = 'PENDING';
        break;
      case 'confirmed':
      case 'accepted':
        color = Colors.blue;
        displayStatus = 'ACCEPTED';
        break;
      case 'in_progress':
        color = Colors.purple;
        displayStatus = 'IN PROGRESS';
        break;
      case 'pending_completion':
        color = Colors.teal;
        displayStatus = 'CHỜ XÁC NHẬN';
        break;
      case 'completed':
        color = Colors.green;
        displayStatus = 'COMPLETED';
        break;
      case 'cancelled':
        color = AppColors.error;
        displayStatus = 'CANCELLED';
        break;
      case 'disputed':
        color = Colors.red;
        displayStatus = 'KHIẾU NẠI';
        break;
      default:
        color = AppColors.textSecondary;
        displayStatus = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
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
      // Customer confirms or disputes completion
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showDisputeDialog(booking.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              icon: const Icon(Icons.warning_amber),
              label: const Text('Khiếu nại'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmCompletion(booking.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text('Xác nhận'),
            ),
          ),
        ],
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

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<BookingsBloc>().add(CancelBooking(bookingId));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(String bookingId, {String? serviceName}) {
    final dataSource = BookingsDataSource();

    ReviewDialog.show(
      context,
      bookingId: bookingId,
      serviceName: serviceName,
      onSubmit: (rating, comment) async {
        await dataSource.reviewBooking(bookingId, rating, comment);
        if (mounted) {
          _refreshBookings();
        }
      },
    );
  }

  Future<void> _confirmCompletion(String bookingId) async {
    try {
      final datasource = BookingsDataSource();
      await datasource.confirmCompletion(bookingId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận hoàn thành! Vui lòng đánh giá dịch vụ.'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh bookings and show review dialog
      _refreshBookings();
      _showReviewDialog(bookingId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDisputeDialog(String bookingId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Khiếu nại'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vui lòng mô tả lý do khiếu nại:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _submitDispute(bookingId, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Gửi khiếu nại'),
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