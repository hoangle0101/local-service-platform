import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/provider_datasource.dart';
import '../../../data/datasources/bookings_datasource.dart';
import '../../../data/datasources/directions_datasource.dart';
import '../../bloc/bookings/bookings_bloc.dart';
import '../../bloc/bookings/bookings_event_state.dart';
import '../../widgets/minimalist_widgets.dart';
import '../../widgets/mini_map_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:async';

// Safe parsing helpers
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

  // Active booking tracking
  Booking? _activeBooking;
  bool _isLoadingActiveBooking = false;
  final BookingsDataSource _bookingsDataSource = BookingsDataSource();

  // Route polyline for active booking
  final DirectionsDataSource _directionsDataSource = DirectionsDataSource();
  List<LatLng> _routePoints = [];
  DirectionsResult? _directionsResult;

  LatLng? _currentLocation;
  bool _isLocating = true;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadActiveBooking();
    _determinePosition();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    if (mounted) setState(() => _isLocating = true);

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLocating = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLocating = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLocating = false);
      return;
    }

    // Get initial position
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLocating = false;
        });

        // Fetch route after position is determined
        _fetchRouteToBooking();

        // Use post frame callback to ensure MapController is attached to FlutterMap
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentLocation != null) {
            try {
              _mapController.move(_currentLocation!, 15.0);
              // Fit map to show both markers if we have a booking
              if (_activeBooking != null &&
                  _activeBooking!.latitude != null &&
                  _activeBooking!.longitude != null) {
                final bounds = LatLngBounds.fromPoints([
                  _currentLocation!,
                  LatLng(_activeBooking!.latitude!, _activeBooking!.longitude!),
                ]);
                _mapController.fitCamera(
                  CameraFit.bounds(
                      bounds: bounds, padding: const EdgeInsets.all(80)),
                );
              }
            } catch (e) {
              debugPrint('Map move error: $e');
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLocating = false);
    }

    // Subscribe to updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
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

  Future<void> _loadActiveBooking() async {
    if (!mounted) return;
    setState(() => _isLoadingActiveBooking = true);
    try {
      debugPrint('[ProviderHomeScreen] Loading active booking...');
      final activeBooking = await _bookingsDataSource.getActiveBooking();
      debugPrint(
          '[ProviderHomeScreen] Active booking result: ${activeBooking?.id} - ${activeBooking?.status}');
      debugPrint(
          '[ProviderHomeScreen] Booking location: lat=${activeBooking?.latitude}, lng=${activeBooking?.longitude}');
      if (!mounted) return;
      setState(() {
        _activeBooking = activeBooking;
        _isLoadingActiveBooking = false;
      });

      // Fetch route if we have an active booking with location
      if (activeBooking != null &&
          activeBooking.latitude != null &&
          activeBooking.longitude != null) {
        debugPrint(
            '[ProviderHomeScreen] Booking has location, fetching route...');
        await _fetchRouteToBooking();
      } else {
        debugPrint(
            '[ProviderHomeScreen] Booking has NO location, cannot fetch route');
      }
    } catch (e) {
      debugPrint('[ProviderHomeScreen] Error loading active booking: $e');
      if (!mounted) return;
      setState(() => _isLoadingActiveBooking = false);
    }
  }

  Future<void> _fetchRouteToBooking() async {
    if (_currentLocation == null || _activeBooking == null) return;
    if (_activeBooking!.latitude == null || _activeBooking!.longitude == null) {
      return;
    }

    try {
      debugPrint('[ProviderHomeScreen] Fetching route...');
      final result = await _directionsDataSource.getRoute(
        origin: _currentLocation!,
        destination:
            LatLng(_activeBooking!.latitude!, _activeBooking!.longitude!),
      );

      if (!mounted) return;
      setState(() {
        _routePoints = result.routePoints;
        _directionsResult = result;
      });
      debugPrint(
          '[ProviderHomeScreen] Route fetched: ${result.routePoints.length} points');
    } catch (e) {
      debugPrint('[ProviderHomeScreen] Error fetching route: $e');
    }
  }

  Future<void> _toggleAvailability() async {
    final newStatus = !_isAvailable;
    // Optimistic UI update
    setState(() => _isAvailable = newStatus);

    try {
      await ProviderDataSource().updateAvailability(newStatus);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAvailable = !newStatus); // Rollback
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerified = _verificationStatus == 'verified';

    if (_isLoadingStats || (_currentLocation == null && _isLocating)) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Đang xác định vị trí...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!isVerified || !_isPhoneVerified) {
      return _buildVerificationRequiredScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<BookingsBloc, BookingsState>(
        listener: (context, state) {
          if (state is BookingsLoaded || state is BookingActionSuccess) {
            _loadActiveBooking();
            _loadStatistics(); // Reload stats (earnings) too
          }
        },
        child: Stack(
          children: [
            // 1. Full-screen Map Background with Route
            Positioned.fill(
              child: _currentLocation == null
                  ? Container(color: AppColors.shelf)
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation!,
                        initialZoom: 15.0,
                      ),
                      children: [
                        // Map tiles
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.localservice.app',
                        ),

                        // Route polyline (if available)
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 5,
                                color: AppColors.primary,
                              ),
                            ],
                          ),

                        // Markers
                        MarkerLayer(
                          markers: [
                            // Provider current location marker
                            Marker(
                              point: _currentLocation!,
                              width: 50,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),

                            // Customer destination marker (if active booking)
                            if (_activeBooking != null &&
                                _activeBooking!.latitude != null &&
                                _activeBooking!.longitude != null)
                              Marker(
                                point: LatLng(_activeBooking!.latitude!,
                                    _activeBooking!.longitude!),
                                width: 50,
                                height: 60,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),

            // 2. Top Bar (Earnings & Toggle)
            _buildTopFloatingBar(),

            // 3. Bottom Panels
            _buildBottomUI(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopFloatingBar() {
    final totalEarnings = _safeDouble(_statistics?['totalEarnings']);
    final currencyFormat =
        NumberFormat.compactCurrency(locale: 'vi_VN', symbol: '₫');

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'THU NHẬP HÔM NAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      currencyFormat.format(totalEarnings),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _toggleAvailability,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          _isAvailable ? AppColors.success : AppColors.warning,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isAvailable
                              ? Icons.bolt_rounded
                              : Icons.pause_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAvailable ? 'SẴN SÀNG' : 'TẠM NGHỈ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomUI() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Recenter Button
          GestureDetector(
            onTap: () {
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 15.0);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.my_location_rounded,
                  color: AppColors.textPrimary, size: 24),
            ),
          ),
          const SizedBox(height: 16),
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // ACTIVE JOB UI - Show current job if exists
                if (_activeBooking != null) ...[
                  _buildActiveJobCard(),
                ] else ...[
                  // IDLE STATE UI - "Đang tìm đơn" or "Tắt nhận đơn"
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isAvailable
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.shelf,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isAvailable
                              ? Icons.search_rounded
                              : Icons.bedtime_rounded,
                          color: _isAvailable
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isAvailable
                                  ? 'Đang tìm đơn hàng...'
                                  : 'Bạn đã tắt nhận đơn',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _isAvailable
                                  ? 'Di chuyển đến khu vực đông đúc để nhanh có đơn.'
                                  : 'Bật nhận đơn để bắt đầu ngày làm việc.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/provider/job-market'),
                    icon:
                        const Icon(Icons.explore_rounded, color: Colors.white),
                    label: const Text('TÌM VIỆC MỚI',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/provider/bookings'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('LỊCH SỬ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.push('/provider/profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('HỒ SƠ',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
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

  /// Build the active job card for the bottom panel
  Widget _buildActiveJobCard() {
    final booking = _activeBooking!;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final isInProgress = booking.status == 'in_progress';
    final isPendingCompletion = booking.status == 'pending_completion';

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isPendingCompletion) {
      statusText = 'Chờ khách xác nhận';
      statusColor = AppColors.warning;
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isInProgress) {
      statusText = 'Đang thực hiện';
      statusColor = AppColors.primary;
      statusIcon = Icons.construction_rounded;
    } else {
      statusText = 'Đã nhận việc';
      statusColor = AppColors.accent;
      statusIcon = Icons.check_circle_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status & Service name
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.serviceName ?? 'Dịch vụ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Thu nhập',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  currencyFormat.format(
                      double.tryParse(booking.estimatedPrice ?? '0') ?? 0),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Customer info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.shelf,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildJobInfoRow(
                  Icons.person_rounded, booking.customerName ?? 'Khách hàng'),
              const SizedBox(height: 8),
              _buildJobInfoRow(Icons.location_on_rounded,
                  booking.addressText ?? 'Địa chỉ không rõ'),
              if (booking.scheduledAt != null) ...[
                const SizedBox(height: 8),
                _buildJobInfoRow(
                  Icons.access_time_rounded,
                  DateFormat('HH:mm - dd/MM/yyyy').format(booking.scheduledAt!),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Action Buttons
        if (!isPendingCompletion) ...[
          // Navigation button
          if (booking.latitude != null && booking.longitude != null)
            ElevatedButton.icon(
              onPressed: () => context.push('/provider/navigation', extra: {
                'lat': booking.latitude,
                'lng': booking.longitude,
                'address': booking.addressText,
                'customerName': booking.customerName,
              }),
              icon: const Icon(Icons.navigation_rounded, color: Colors.white),
              label: const Text('CHỈ ĐƯỜNG ĐẾN KHÁCH',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          // Chat button
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push(
              '/chat/${booking.id}',
              extra: booking.customerName,
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('NHẮN TIN VỚI KHÁCH',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Primary action based on status
        Row(
          children: [
            if (!isInProgress && !isPendingCompletion)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _bookingsDataSource.startService(booking.id);
                    _loadActiveBooking();
                  },
                  icon:
                      const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text('BẮT ĐẦU',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            if (isInProgress)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _bookingsDataSource.completeService(booking.id);
                    _loadActiveBooking();
                  },
                  icon: const Icon(Icons.check_circle_rounded,
                      color: Colors.white),
                  label: const Text('HOÀN THÀNH',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            if (isPendingCompletion)
              const Expanded(
                child: Center(
                  child: Text(
                    'Đang chờ khách hàng xác nhận hoàn thành...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildJobInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
