import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/entities/entities.dart';
import '../../../data/datasources/track_asia_datasource.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/minimalist_widgets.dart';

class CreateBookingScreen extends StatefulWidget {
  final int serviceId;
  final ProviderService? service;
  final int? providerId; // For direct booking

  const CreateBookingScreen({
    super.key,
    required this.serviceId,
    this.service,
    this.providerId,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Default location (Hanoi)
  double _latitude = 21.0285;
  double _longitude = 105.8542;

  // Track Asia API for address autocomplete
  final TrackAsiaDataSource _trackAsiaDataSource = TrackAsiaDataSource();
  List<AddressPrediction> _addressPredictions = [];
  Timer? _debounceTimer;
  bool _showPredictions = false;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Search for addresses using Track Asia API
  void _onAddressSearch(String query) {
    _debounceTimer?.cancel();

    if (query.length < 3) {
      setState(() {
        _addressPredictions = [];
        _showPredictions = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final predictions = await _trackAsiaDataSource.searchAddress(query);
        if (mounted) {
          setState(() {
            _addressPredictions = predictions;
            _showPredictions = predictions.isNotEmpty;
          });
        }
      } catch (e) {
        debugPrint('[CreateBooking] Address search error: $e');
      }
    });
  }

  /// Select an address from predictions
  Future<void> _selectAddress(AddressPrediction prediction) async {
    setState(() => _showPredictions = false);

    try {
      final detail =
          await _trackAsiaDataSource.getPlaceDetail(prediction.placeId);
      if (mounted && detail != null) {
        // Use FullAddress for better display
        final fullAddress = FullAddress.fromPlaceDetail(detail);
        setState(() {
          _addressController.text = fullAddress.displayText;
          _latitude = fullAddress.latitude;
          _longitude = fullAddress.longitude;
        });
      } else {
        setState(() => _addressController.text = prediction.description);
      }
    } catch (e) {
      debugPrint('[CreateBooking] Place detail error: $e');
      setState(() => _addressController.text = prediction.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingsBloc(),
      child: BlocConsumer<BookingsBloc, BookingsState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Booking ${state.bookingCode} created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            // Show success dialog
            _showSuccessDialog(context, state);
          } else if (state is BookingsError) {
            // Show error dialog for better visibility
            _showErrorDialog(context, state.message);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.white,
            body: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context),
                SliverToBoxAdapter(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildServiceInfo(),
                          const SizedBox(height: 32),
                          _buildLabel('Thời gian thực hiện'),
                          _buildDateTimeSection(),
                          const SizedBox(height: 32),
                          _buildLabel('Địa điểm cần đến'),
                          _buildLocationSection(),
                          const SizedBox(height: 32),
                          _buildLabel('Ghi chú thêm'),
                          _buildNotesSection(),
                          const SizedBox(height: 32),
                          _buildPriceSummary(),
                          const SizedBox(height: 40),
                          _buildSubmitButton(context, state),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, BookingCreated state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Created!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Booking Code: ${state.bookingCode}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (state.isDirectBooking)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_pin, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đã gửi yêu cầu đặt lịch đến provider. Vui lòng chờ xác nhận.',
                        style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
            else if (state.nearbyProviderIds.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No nearby providers found. We will notify you when one is available.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${state.nearbyProviderIds.length} providers found nearby!',
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/user/bookings'); // Go to bookings screen
            },
            child: const Text('View My Bookings'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/user/home'); // Go to user home, not guest home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    // Extract meaningful message from error
    String displayMessage = errorMessage;
    if (errorMessage.contains('Failed to create booking:')) {
      displayMessage =
          errorMessage.replaceFirst('Failed to create booking:', '').trim();
    }
    if (displayMessage.contains('Exception:')) {
      displayMessage = displayMessage.replaceFirst('Exception:', '').trim();
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.error_outline, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Không thể đặt lịch', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          displayMessage,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 120,
      backgroundColor: AppColors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.divider.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 20),
              const Text(
                'Đặt dịch vụ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildServiceInfo() {
    if (widget.service == null) {
      return MinCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.shelf,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.home_repair_service_rounded,
                  color: AppColors.textTertiary),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Đang tải thông tin dịch vụ...',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return MinCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.home_repair_service_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service!.service.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_rounded,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      widget.service!.provider.displayName,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.divider.withOpacity(0.5), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ngày',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w700)),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.divider.withOpacity(0.5), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Giờ',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w700)),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MinTextField(
          controller: _addressController,
          hint: 'Nhập địa chỉ của bạn...',
          prefixIcon: const Icon(Icons.location_on_rounded,
              color: AppColors.primary, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.my_location_rounded,
                color: AppColors.primary, size: 18),
            onPressed: _getCurrentLocation,
          ),
          onChanged: _onAddressSearch,
        ),
        if (_showPredictions && _addressPredictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addressPredictions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppColors.divider.withOpacity(0.3)),
              itemBuilder: (context, index) {
                final prediction = _addressPredictions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined,
                      size: 18, color: AppColors.textTertiary),
                  title: Text(prediction.mainText,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(prediction.secondaryText,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary)),
                  onTap: () => _selectAddress(prediction),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.shelf.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.gps_fixed_rounded,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 10),
              Text(
                'Tọa độ: ${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _getCurrentLocation() {
    // For simplicity, use default Hanoi location
    // In production, use geolocator package
    setState(() {
      _addressController.text = 'Hoàn Kiếm, Hà Nội, Việt Nam';
      _latitude = 21.0285;
      _longitude = 105.8542;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.location_on, color: Colors.white),
            SizedBox(width: 8),
            Text('Using default location (Hanoi)'),
          ],
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildNotesSection() {
    return MinTextField(
      controller: _notesController,
      maxLines: 4,
      hint: 'Ví dụ: Hướng dẫn tìm đường, số tầng, lưu ý đặc biệt...',
      prefixIcon: const Icon(Icons.note_alt_rounded,
          color: AppColors.primary, size: 20),
    );
  }

  Widget _buildPriceSummary() {
    final price = widget.service?.price ?? 0;

    return MinCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: AppColors.shelf.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Giá dịch vụ',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
              Text(
                NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                    .format(price),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng tạm tính',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary),
              ),
              Text(
                NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                    .format(price),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.textTertiary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Giá cuối cùng có thể thay đổi dựa trên thỏa thuận trực tiếp.',
                  style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, BookingsState state) {
    return MinButton(
      text: 'Xác nhận đặt lịch',
      onPressed: () => _submitBooking(context),
      isLoading: state is BookingsLoading,
    );
  }

  void _submitBooking(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      context.read<BookingsBloc>().add(CreateBookingEvent(
            serviceId: widget.serviceId,
            scheduledAt: scheduledAt,
            addressText: _addressController.text,
            latitude: _latitude,
            longitude: _longitude,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            providerId: widget.providerId, // Pass provider for direct booking
          ));
    }
  }
}
