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
import '../../bloc/services/services_bloc.dart';
import '../../bloc/services/services_event_state.dart';

class NewBookingScreen extends StatefulWidget {
  final int? categoryId;

  const NewBookingScreen({super.key, this.categoryId});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected service
  ProviderService? _selectedService;

  // Date and time
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  // Location
  double _latitude = 21.0285;
  double _longitude = 105.8542;

  int _currentStep = 0;

  // Track Asia API for address autocomplete
  final TrackAsiaDataSource _trackAsiaDataSource = TrackAsiaDataSource();
  List<AddressPrediction> _addressPredictions = [];
  Timer? _debounceTimer;
  bool _showPredictions = false;

  @override
  void initState() {
    super.initState();
    // Load services
    context.read<ServicesBloc>().add(const LoadServices());
  }

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
        debugPrint('[NewBooking] Address search error: $e');
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
      debugPrint('[NewBooking] Place detail error: $e');
      setState(() => _addressController.text = prediction.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingsBloc(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          title: const Text('Book a Service'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: BlocConsumer<BookingsBloc, BookingsState>(
          listener: (context, state) {
            if (state is BookingCreated) {
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
          builder: (context, bookingState) {
            return Stepper(
              currentStep: _currentStep,
              onStepContinue: () => _handleStepContinue(context, bookingState),
              onStepCancel: _handleStepCancel,
              controlsBuilder: (context, details) {
                return _buildStepControls(context, details, bookingState);
              },
              steps: [
                Step(
                  title: const Text('Select Service'),
                  subtitle: _selectedService != null
                      ? Text(_selectedService!.service.name)
                      : null,
                  isActive: _currentStep >= 0,
                  state:
                      _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: _buildServiceSelectionStep(),
                ),
                Step(
                  title: const Text('Schedule'),
                  subtitle: _currentStep > 1
                      ? Text(DateFormat('EEE, dd MMM • HH:mm').format(DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute)))
                      : null,
                  isActive: _currentStep >= 1,
                  state:
                      _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: _buildScheduleStep(),
                ),
                Step(
                  title: const Text('Location & Details'),
                  isActive: _currentStep >= 2,
                  state:
                      _currentStep > 2 ? StepState.complete : StepState.indexed,
                  content: _buildLocationStep(),
                ),
                Step(
                  title: const Text('Confirm'),
                  isActive: _currentStep >= 3,
                  content: _buildConfirmationStep(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceSelectionStep() {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        if (state is ServicesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ServicesLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose the service you need:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              ...state.services.map((service) => _buildServiceOption(service)),
            ],
          );
        } else if (state is ServicesError) {
          return Center(
            child: Column(
              children: [
                Text('Error: ${state.message}'),
                ElevatedButton(
                  onPressed: () =>
                      context.read<ServicesBloc>().add(const LoadServices()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('Loading services...'));
      },
    );
  }

  Widget _buildServiceOption(ProviderService service) {
    final isSelected = _selectedService?.serviceId == service.serviceId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedService = service;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getServiceIcon(service.service.name),
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.service.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (service.provider.displayName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.provider.displayName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                          .format(service.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'When do you need the service?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),

        // Date Selection
        const Text('Select Date',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14, // Next 14 days
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index + 1));
              final isSelected = _selectedDate.day == date.day &&
                  _selectedDate.month == date.month &&
                  _selectedDate.year == date.year;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Time Selection
        const Text('Select Time',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int hour = 8; hour <= 18; hour += 2)
              _buildTimeChip(TimeOfDay(hour: hour, minute: 0)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeChip(TimeOfDay time) {
    final isSelected =
        _selectedTime.hour == time.hour && _selectedTime.minute == time.minute;

    return ChoiceChip(
      label: Text(time.format(context)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedTime = time;
          });
        }
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildLocationStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Địa điểm cần đến',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Sử dụng Track Asia API để tìm địa chỉ chính xác',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // Address input with autocomplete
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Địa chỉ',
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
            maxLines: 2,
          ),

          // Address predictions dropdown
          if (_showPredictions && _addressPredictions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 200),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      prediction.mainText,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      prediction.secondaryText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    onTap: () => _selectAddress(prediction),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // GPS coordinates display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tọa độ: ${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Ghi chú thêm (Tùy chọn)',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Yêu cầu đặc biệt hoặc hướng dẫn...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    if (_selectedService == null) {
      return const Center(child: Text('Please select a service first'));
    }

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Service Card
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow(
                  Icons.home_repair_service,
                  'Service',
                  _selectedService!.service.name,
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  Icons.calendar_today,
                  'Date & Time',
                  DateFormat('EEE, dd MMM yyyy • HH:mm').format(scheduledAt),
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  Icons.location_on,
                  'Location',
                  _addressController.text.isNotEmpty
                      ? _addressController.text
                      : 'Not specified',
                ),
                if (_notesController.text.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildSummaryRow(
                    Icons.note,
                    'Notes',
                    _notesController.text,
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Price
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Price',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                    .format(_selectedService!.price),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Text(
          '* Final price may vary based on the actual work required',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepControls(
    BuildContext context,
    ControlsDetails details,
    BookingsState bookingState,
  ) {
    final isLoading = bookingState is BookingsLoading;
    final isLastStep = _currentStep == 3;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : details.onStepCancel,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLoading ? null : details.onStepContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep ? Colors.green : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(isLastStep ? 'Confirm Booking' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStepContinue(BuildContext context, BookingsState bookingState) {
    if (_currentStep == 0) {
      if (_selectedService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a service'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      _submitBooking(context);
    }
  }

  void _handleStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _submitBooking(BuildContext context) {
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    context.read<BookingsBloc>().add(CreateBookingEvent(
          serviceId: _selectedService!.serviceId,
          scheduledAt: scheduledAt,
          addressText: _addressController.text,
          latitude: _latitude,
          longitude: _longitude,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        ));
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
              'Booking Confirmed!',
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
                        'No providers nearby. We will notify you when one is available.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
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
                        '${state.nearbyProviderIds.length} provider(s) found nearby!',
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
              context.go('/user/bookings');
            },
            child: const Text('View My Bookings'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/user/home');
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

  void _getCurrentLocation() {
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

  IconData _getServiceIcon(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('clean')) return Icons.cleaning_services;
    if (name.contains('plumb')) return Icons.plumbing;
    if (name.contains('electr')) return Icons.electrical_services;
    if (name.contains('paint')) return Icons.format_paint;
    if (name.contains('ac') || name.contains('air')) return Icons.ac_unit;
    if (name.contains('repair')) return Icons.build;
    return Icons.home_repair_service;
  }
}
