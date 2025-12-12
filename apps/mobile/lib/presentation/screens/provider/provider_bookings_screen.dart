import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/bookings_datasource.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingsDataSource _bookingsDataSource = BookingsDataSource();

  // Separate lists for different request types
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi tải yêu cầu: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadGlobalRequests() async {
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
        // Silently fail for global - it's secondary
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Công việc của tôi'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryDark,
          isScrollable: true,
          tabs: [
            _buildTab('Yêu cầu', _myRequests.length),
            _buildTab('Xa hơn', _globalRequests.length),
            const Tab(text: 'Đang làm'),
            const Tab(text: 'Hoàn thành'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: My Requests (within radius)
          _buildMyRequestsTab(),
          // Tab 2: Global Requests (outside radius)
          _buildGlobalRequestsTab(),
          // Tab 3: In Progress (includes accepted, confirmed, in_progress)
          BlocBuilder<BookingsBloc, BookingsState>(
            builder: (context, state) {
              if (state is BookingsLoaded) {
                final inProgress = state.bookings
                    .where((b) =>
                        b.status == 'accepted' ||
                        b.status == 'confirmed' ||
                        b.status == 'in_progress')
                    .toList();
                return _buildBookingsList(inProgress, 'in_progress');
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
          // Tab 4: Completed
          BlocBuilder<BookingsBloc, BookingsState>(
            builder: (context, state) {
              if (state is BookingsLoaded) {
                final completed = state.bookings
                    .where((b) => b.status == 'completed')
                    .toList();
                return _buildBookingsList(completed, 'completed');
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ],
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
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    if (_isLoadingMyRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myRequests.isEmpty) {
      return _buildEmptyState(
        'Chưa có yêu cầu nào',
        'Các yêu cầu trong phạm vi hoạt động của bạn sẽ hiển thị ở đây',
        Icons.location_on_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myRequests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(_myRequests[index], isGlobal: false);
        },
      ),
    );
  }

  Widget _buildGlobalRequestsTab() {
    if (_isLoadingGlobalRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_globalRequests.isEmpty) {
      return _buildEmptyState(
        'Không có yêu cầu xa hơn',
        'Các yêu cầu ngoài phạm vi đăng ký của bạn sẽ hiển thị ở đây',
        Icons.public,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGlobalRequests,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Các yêu cầu này nằm ngoài phạm vi đăng ký. Bạn có thể nhận nếu muốn mở rộng.',
                    style:
                        TextStyle(color: Colors.orange.shade800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _globalRequests.length,
              itemBuilder: (context, index) {
                return _buildRequestCard(_globalRequests[index],
                    isGlobal: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Booking booking, {required bool isGlobal}) {
    final distanceKm = (booking.distance ?? 0) / 1000;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isGlobal
                        ? Colors.orange.shade50
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isGlobal ? Icons.public : Icons.work_outline,
                    color: isGlobal ? Colors.orange : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName ?? 'Dịch vụ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.customerName ?? 'Khách hàng',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${distanceKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: isGlobal
                            ? Colors.orange.shade700
                            : AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isGlobal)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Xa hơn',
                          style: TextStyle(
                              color: Colors.orange.shade800, fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.addressText ?? '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  booking.scheduledAt != null
                      ? DateFormat('HH:mm - dd/MM/yyyy')
                          .format(booking.scheduledAt!)
                      : 'Chưa xác định',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const Spacer(),
                if (booking.estimatedPrice != null)
                  Text(
                    '~${_formatPrice(double.tryParse(booking.estimatedPrice!) ?? 0)} VND',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptRequest(booking),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Nhận việc'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _viewDetails(booking),
                  child: const Text('Chi tiết'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, String tab) {
    if (bookings.isEmpty) {
      String message = 'Chưa có công việc nào';
      if (tab == 'in_progress') {
        message = 'Chưa có công việc đang thực hiện';
      } else if (tab == 'completed') {
        message = 'Chưa hoàn thành công việc nào';
      }
      return _buildEmptyState(message, '', Icons.work_off_outlined);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<BookingsBloc>().add(const LoadProviderBookings());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    Color statusColor = Colors.grey;
    String statusText = booking.status ?? 'Không rõ';

    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.blue;
        statusText = 'Đã xác nhận';
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusText = 'Đang thực hiện';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Hoàn thành';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.serviceName ?? 'Dịch vụ',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              booking.customerName ?? 'Khách hàng',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              booking.addressText ?? '',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            // Show Start button for both accepted and confirmed status
            if (booking.status == 'accepted' || booking.status == 'confirmed')
              ElevatedButton.icon(
                onPressed: () => _startService(booking),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Bắt đầu dịch vụ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            if (booking.status == 'in_progress')
              ElevatedButton.icon(
                onPressed: () => _completeService(booking),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Hoàn thành'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  Future<void> _acceptRequest(Booking booking) async {
    try {
      final bookingId = int.tryParse(booking.id) ?? 0;
      final result = await _bookingsDataSource.acceptBookingRequest(bookingId);

      // Check if this was a direct booking (auto-accepted)
      final isDirectBooking = result['isDirectBooking'] == true;
      final message = isDirectBooking
          ? 'Đã chấp nhận đặt lịch! Booking chuyển sang tab Đang làm.'
          : 'Đã gửi đề nghị thành công!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );

      // Reload all data including BLoC for "Đang làm" tab
      _loadAllData();
      context.read<BookingsBloc>().add(const LoadProviderBookings());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _viewDetails(Booking booking) {
    // TODO: Navigate to booking details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chi tiết đơn ${booking.code}')),
    );
  }

  Future<void> _startService(Booking booking) async {
    try {
      await _bookingsDataSource.startService(booking.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã bắt đầu dịch vụ!'),
            backgroundColor: Colors.green),
      );
      context.read<BookingsBloc>().add(const LoadProviderBookings());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _completeService(Booking booking) async {
    try {
      await _bookingsDataSource.completeService(booking.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã hoàn thành dịch vụ!'),
            backgroundColor: Colors.green),
      );
      context.read<BookingsBloc>().add(const LoadProviderBookings());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
