import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/quote_datasource.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/minimalist_widgets.dart';
import '../../widgets/booking_offers_dialog.dart';
import '../provider/create_quote_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;
  final bool isProvider;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    this.isProvider = false,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final QuoteDataSource _quoteDataSource = QuoteDataSource();
  bool _isActionLoading = false;

  void _onActionSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context); // Go back after success
    }
  }

  void _onActionError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final price = double.tryParse(widget.booking.estimatedPrice ?? '0') ?? 0;

    return BlocListener<BookingsBloc, BookingsState>(
      listener: (context, state) {
        if (state is BookingActionSuccess) {
          _onActionSuccess(state.message);
        } else if (state is BookingsError) {
          _onActionError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Chi tiết đơn hàng',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Section
              _buildStatusHeader(),
              const SizedBox(height: 24),

              // Service Info
              _buildSectionTitle('DỊCH VỤ'),
              MinCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.cleaning_services_rounded,
                              color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.booking.serviceName ?? 'Dịch vụ',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (widget.booking.categoryName != null)
                                Text(
                                  widget.booking.categoryName!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.booking.notes != null &&
                        widget.booking.notes!.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: AppColors.divider),
                      ),
                      const Text(
                        'Ghi chú từ khách hàng:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.booking.notes!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Time and Date
              _buildSectionTitle('THỜI GIAN'),
              MinCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildDateTimeItem(
                      Icons.calendar_month_rounded,
                      'Ngày thực hiện',
                      widget.booking.scheduledAt != null
                          ? dateFormat.format(widget.booking.scheduledAt!)
                          : 'N/A',
                    ),
                    const SizedBox(width: 24),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.divider.withOpacity(0.5),
                    ),
                    const SizedBox(width: 24),
                    _buildDateTimeItem(
                      Icons.access_time_filled_rounded,
                      'Giờ bắt đầu',
                      widget.booking.scheduledAt != null
                          ? timeFormat.format(widget.booking.scheduledAt!)
                          : 'N/A',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Location Section
              _buildSectionTitle('ĐỊA ĐIỂM'),
              MinCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildLocationRow(
                      Icons.my_location_rounded,
                      'Địa chỉ khách hàng',
                      widget.booking.addressText ?? 'N/A',
                      AppColors.primary,
                    ),
                    if (widget.booking.providerAddress != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: AppColors.divider),
                      ),
                      _buildLocationRow(
                        Icons.store_rounded,
                        'Địa chỉ đối tác',
                        widget.booking.providerAddress!,
                        AppColors.accent,
                      ),
                    ],
                    if (widget.booking.distance != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.shelf.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car_rounded,
                                size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 10),
                            Text(
                              'Khoảng cách: ${widget.booking.distance! < 1000 ? "${widget.booking.distance} m" : "${(widget.booking.distance! / 1000).toStringAsFixed(1)} km"}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Provider/Customer Info
              _buildSectionTitle(widget.isProvider ? 'KHÁCH HÀNG' : 'ĐỐI TÁC'),
              MinCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.shelf,
                      child: Icon(Icons.person_rounded,
                          color: AppColors.textTertiary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (widget.isProvider
                                    ? widget.booking.customerName
                                    : widget.booking.providerName) ??
                                'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.isProvider
                                ? 'Khách hàng'
                                : 'Người cung cấp dịch vụ',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {}, // TODO: Chat integration
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_rounded,
                            color: AppColors.primary, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Info
              _buildSectionTitle('THANH TOÁN'),
              MinCard(
                padding: const EdgeInsets.all(24),
                backgroundColor: AppColors.white,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng thanh toán',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          price > 0
                              ? currencyFormat
                                  .format(price)
                                  .replaceAll(',00', '')
                              : 'CHỜ BÁO GIÁ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: price > 0
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    if (price == 0) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Thợ sẽ kiểm tra tình trạng thực tế và gửi báo giá lại cho bạn sau.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Action Buttons
              _buildActionButtons(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDetailStatusBadge(widget.booking.status),
        Text(
          '#${widget.booking.code}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textTertiary.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailStatusBadge(String status) {
    Color color = AppColors.textTertiary;
    String label = status.toUpperCase();

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        label = 'ĐANG CHỜ';
        break;
      case 'accepted':
      case 'confirmed':
        color = AppColors.accent;
        label = 'ĐÃ NHẬN';
        break;
      case 'in_progress':
        color = AppColors.primary;
        label = 'ĐANG LÀM';
        break;
      case 'completed':
        color = AppColors.success;
        label = 'HOÀN THÀNH';
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'ĐÃ HỦY';
        break;
      case 'disputed':
        color = AppColors.error;
        label = 'BÁO GIÁ BỊ TỪ CHỐI';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDateTimeItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final status = widget.booking.status;
    final id = widget.booking.id;

    if (widget.isProvider) {
      if (status == 'accepted' || status == 'confirmed') {
        return MinButton(
          text: 'Bắt đầu dịch vụ',
          isFullWidth: true,
          isLoading: _isActionLoading,
          onPressed: () => context.read<BookingsBloc>().add(StartService(id)),
          icon: Icons.play_arrow_rounded,
        );
      }
      if (status == 'in_progress') {
        return Column(
          children: [
            MinButton(
              text: 'Tạo Báo Giá',
              isFullWidth: true,
              isPrimary: false,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => CreateQuoteScreen(
                    bookingId: widget.booking.id,
                    serviceName: widget.booking.serviceName,
                    serviceId: widget.booking.serviceId,
                    providerId: widget.booking.providerId,
                    customerSelectedItems: widget.booking.selectedItems,
                  ),
                ),
              ),
              icon: Icons.receipt_long_rounded,
            ),
            const SizedBox(height: 12),
            MinButton(
              text: 'Hoàn thành việc',
              isFullWidth: true,
              isLoading: _isActionLoading,
              onPressed: () =>
                  context.read<BookingsBloc>().add(CompleteService(id)),
              icon: Icons.check_circle_rounded,
            ),
          ],
        );
      }
      if (status == 'disputed') {
        return MinButton(
          text: 'Đồng ý hủy đơn',
          isFullWidth: true,
          isPrimary: false,
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.error,
          onPressed: _handleProviderAgreeReject,
          icon: Icons.cancel_outlined,
        );
      }
    } else {
      // Customer actions
      if (status == 'pending') {
        if (!widget.booking.isDirectBooking) {
          return MinButton(
            text: 'Xem các báo giá (${widget.booking.offersCount})',
            isFullWidth: true,
            onPressed: () => _showOffersDialog(context),
            icon: Icons.local_offer_rounded,
          );
        }
        return MinButton(
          text: 'Hủy yêu cầu',
          isFullWidth: true,
          isPrimary: false,
          onPressed: () => _showCancelDialog(context),
          icon: Icons.close_rounded,
        );
      }
      if (status == 'accepted' ||
          status == 'confirmed' ||
          status == 'in_progress') {
        return MinButton(
          text: 'Hủy đơn hàng',
          isFullWidth: true,
          isPrimary: false,
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.error,
          onPressed: () => _showCancelDialog(context),
          icon: Icons.cancel_outlined,
        );
      }
    }

    return const SizedBox.shrink();
  }

  void _showOffersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BookingOffersDialog(
        bookingId: widget.booking.id,
        onProviderSelected: () {
          // Reloaing since a provider was selected
          context.read<BookingsBloc>().add(const LoadBookings());
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập lý do hủy đơn:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Lý do...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton(
            onPressed: () {
              context
                  .read<BookingsBloc>()
                  .add(CancelBooking(widget.booking.id, reasonController.text));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleProviderAgreeReject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc chắn muốn đồng ý hủy đơn này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Không')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child:
                const Text('Đồng ý hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      final quotes =
          await _quoteDataSource.getQuotesForBooking(widget.booking.id);
      final rejectedQuote = quotes.firstWhere(
        (q) => q['status'] == 'rejected',
        orElse: () => <String, dynamic>{},
      );

      if (rejectedQuote.isEmpty || rejectedQuote['id'] == null) {
        throw Exception('Không tìm thấy báo giá bị từ chối');
      }

      await _quoteDataSource
          .providerAgreeReject(rejectedQuote['id'].toString());
      _onActionSuccess('Đã hủy đơn hàng thành công');
    } catch (e) {
      _onActionError(e.toString());
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }
}
