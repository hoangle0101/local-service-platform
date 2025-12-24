import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/provider_datasource.dart';
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

  LatLng? _currentLocation;
  bool _isLocating = true;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
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

        // Use post frame callback to ensure MapController is attached to FlutterMap
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentLocation != null) {
            try {
              _mapController.move(_currentLocation!, 15.0);
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
      body: Stack(
        children: [
          // 1. Full-screen Map Background
          Positioned.fill(
            child: _currentLocation == null
                ? Container(color: AppColors.shelf)
                : MiniMapWidget(
                    initialCenter: _currentLocation!,
                    initialZoom: 15.0,
                    mapController: _mapController,
                  ),
          ),

          // 2. Top Bar (Earnings & Toggle)
          _buildTopFloatingBar(),

          // 3. Bottom Panels
          _buildBottomUI(),
        ],
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
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
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
            ),
          ),
        ],
      ),
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
