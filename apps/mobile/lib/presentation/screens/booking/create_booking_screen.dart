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

class CreateBookingScreen extends StatefulWidget {
  final int serviceId;
  final ProviderService? service;

  const CreateBookingScreen({
    super.key,
    required this.serviceId,
    this.service,
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Book Service'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildServiceInfo(),
                  const SizedBox(height: 24),
                  _buildDateTimeSection(),
                  const SizedBox(height: 24),
                  _buildLocationSection(),
                  const SizedBox(height: 24),
                  _buildNotesSection(),
                  const SizedBox(height: 24),
                  _buildPriceSummary(),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomBar(context, state),
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
            if (state.nearbyProviderIds.isEmpty)
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

  Widget _buildServiceInfo() {
    if (widget.service == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.home_repair_service, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service #${widget.serviceId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Loading service details...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.home_repair_service, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service!.service.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                      .format(widget.service!.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (widget.service!.provider != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        widget.service!.provider!.displayName,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'When do you need the service?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
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
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            DateFormat('EEE, dd MMM yyyy')
                                .format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
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
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Địa điểm cần đến',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Sử dụng Track Asia API để tìm địa chỉ chính xác',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),

        // Address input with autocomplete
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: 'Nhập địa chỉ để tìm kiếm...',
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location, color: AppColors.primary),
              onPressed: _getCurrentLocation,
            ),
          ),
          onChanged: _onAddressSearch,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập địa chỉ';
            }
            return null;
          },
        ),

        // Address predictions dropdown
        if (_showPredictions && _addressPredictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _addressPredictions.length,
              itemBuilder: (context, index) {
                final prediction = _addressPredictions[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    prediction.mainText,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  subtitle: Text(
                    prediction.secondaryText,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  onTap: () => _selectAddress(prediction),
                );
              },
            ),
          ),

        const SizedBox(height: 8),

        // GPS coordinates display
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.gps_fixed, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tọa độ: ${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.note_alt, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Additional Notes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            Text(
              '(Optional)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any specific instructions or requirements...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    final price = widget.service?.price ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Service Price'),
              Text(
                NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                    .format(price),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Est. Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                    .format(price),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '* Final price may vary based on provider offers',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BookingsState state) {
    final isLoading = state is BookingsLoading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isLoading ? null : () => _submitBooking(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Finding Providers...'),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text(
                      'Find Providers',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      ),
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
          ));
    }
  }
}
