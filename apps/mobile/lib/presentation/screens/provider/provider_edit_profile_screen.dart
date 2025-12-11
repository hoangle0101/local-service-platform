import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/provider_datasource.dart';
import '../../../data/datasources/track_asia_datasource.dart';
import '../../bloc/auth/auth_bloc.dart';

class ProviderEditProfileScreen extends StatefulWidget {
  const ProviderEditProfileScreen({super.key});

  @override
  State<ProviderEditProfileScreen> createState() =>
      _ProviderEditProfileScreenState();
}

class _ProviderEditProfileScreenState extends State<ProviderEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();

  final ProviderDataSource _providerDataSource = ProviderDataSource();
  final TrackAsiaDataSource _trackAsiaDataSource = TrackAsiaDataSource();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSaving = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;

  // Profile image
  File? _selectedImage;
  String? _existingImageUrl;

  List<AddressPrediction> _addressSuggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;

  int _selectedRadius = 5000;
  final List<int> _radiusOptions = [
    1000,
    2000,
    3000,
    5000,
    7000,
    10000,
    15000,
    20000,
    25000,
    30000,
    40000
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadProfile() {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated && state.user?.providerProfile != null) {
      final profile = state.user!.providerProfile!;
      _displayNameController.text = profile.displayName;
      _bioController.text = profile.bio ?? '';
      _addressController.text = profile.address ?? '';
      // Clamp radius to valid range (1000-40000 meters / 1-40km)
      final profileRadius = profile.serviceRadiusM ?? 5000;
      _selectedRadius = profileRadius.clamp(1000, 40000);
      _latitude = profile.latitude;
      _longitude = profile.longitude;
    }
  }

  void _onAddressChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.length < 3) {
      setState(() {
        _addressSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final suggestions = await _trackAsiaDataSource.searchAddress(query);
        if (mounted) {
          setState(() {
            _addressSuggestions = suggestions;
            _showSuggestions = suggestions.isNotEmpty;
          });
        }
      } catch (e) {
        debugPrint('[EditProfile] Address search error: $e');
      }
    });
  }

  Future<void> _selectAddress(AddressPrediction prediction) async {
    setState(() => _showSuggestions = false);

    try {
      final detail =
          await _trackAsiaDataSource.getPlaceDetail(prediction.placeId);
      if (mounted && detail != null) {
        setState(() {
          _addressController.text = prediction.description;
          _latitude = detail.latitude;
          _longitude = detail.longitude;
        });
      } else if (mounted) {
        setState(() => _addressController.text = prediction.description);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'), backgroundColor: Colors.red.shade400),
        );
      }
    }
  }

  /// Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  /// Show bottom sheet to choose image source
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chọn ảnh đại diện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.primary),
              ),
              title: const Text('Chụp ảnh'),
              subtitle: const Text('Sử dụng camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Colors.purple),
              ),
              title: const Text('Chọn từ thư viện'),
              subtitle: const Text('Chọn ảnh có sẵn'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Get current GPS location
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng bật dịch vụ định vị'),
              backgroundColor: Colors.orange.shade400,
              action: SnackBarAction(
                label: 'Mở cài đặt',
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quyền truy cập vị trí bị từ chối'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Quyền vị trí bị từ chối vĩnh viễn'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Mở cài đặt',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get full address
      final address = await _trackAsiaDataSource.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        if (address != null) {
          setState(() {
            _addressController.text = address.displayText;
            _latitude = address.latitude;
            _longitude = address.longitude;
            _isGettingLocation = false;
          });
        } else {
          // Fallback: use coordinates only
          setState(() {
            _addressController.text =
                'Vị trí: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
            _latitude = position.latitude;
            _longitude = position.longitude;
            _isGettingLocation = false;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address != null
                        ? 'Đã lấy địa chỉ: ${address.shortText}'
                        : 'Đã lấy vị trí GPS thành công!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade400,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lấy vị trí: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Upload avatar if selected
      debugPrint(
          '[EditProfile] _selectedImage: ${_selectedImage?.path ?? "null"}');
      if (_selectedImage != null) {
        debugPrint('[EditProfile] Uploading avatar...');
        try {
          final avatarUrl =
              await _providerDataSource.uploadAvatar(_selectedImage!.path);
          debugPrint('[EditProfile] Avatar uploaded successfully: $avatarUrl');
        } catch (e) {
          debugPrint('[EditProfile] Avatar upload error: $e');
          // Continue with profile update even if avatar fails
        }
      } else {
        debugPrint('[EditProfile] No image selected, skipping avatar upload');
      }

      await _providerDataSource.updateProviderProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        serviceRadiusM: _selectedRadius,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (mounted) {
        // Refresh AuthBloc to update profile in app state
        context.read<AuthBloc>().add(const ProfileFetchRequested());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Cập nhật thành công!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          // Premium gradient header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (_isSaving)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Lưu',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withBlue(180),
                      AppColors.primary.withGreen(100),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.edit_note,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chỉnh sửa hồ sơ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Cập nhật thông tin cá nhân',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Form content
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar section
                    _buildAvatarSection(),
                    const SizedBox(height: 24),

                    // Basic info card
                    _buildCard(
                      icon: Icons.person_outline,
                      title: 'Thông tin cơ bản',
                      color: Colors.blue,
                      child: Column(
                        children: [
                          _buildModernTextField(
                            controller: _displayNameController,
                            label: 'Tên hiển thị',
                            hint: 'VD: Nguyễn Văn A',
                            icon: Icons.badge_outlined,
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildModernTextField(
                            controller: _bioController,
                            label: 'Giới thiệu bản thân',
                            hint: 'Kinh nghiệm, chuyên môn, điểm mạnh...',
                            icon: Icons.description_outlined,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location card
                    _buildCard(
                      icon: Icons.location_on_outlined,
                      title: 'Vị trí hoạt động',
                      color: Colors.green,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernTextField(
                            controller: _addressController,
                            label: 'Địa chỉ',
                            hint: 'Nhập địa chỉ để tìm kiếm...',
                            icon: Icons.search,
                            onChanged: _onAddressChanged,
                          ),

                          // Address suggestions
                          if (_showSuggestions &&
                              _addressSuggestions.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(maxHeight: 220),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _addressSuggestions.length,
                                  separatorBuilder: (_, __) => Divider(
                                      height: 1, color: Colors.grey.shade200),
                                  itemBuilder: (context, index) {
                                    final s = _addressSuggestions[index];
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 4),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.location_on,
                                            color: Colors.green.shade600,
                                            size: 20),
                                      ),
                                      title: Text(s.mainText,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      subtitle: Text(
                                        s.secondaryText,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () => _selectAddress(s),
                                    );
                                  },
                                ),
                              ),
                            ),

                          // GPS Location Button
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            child: ElevatedButton.icon(
                              onPressed: _isGettingLocation
                                  ? null
                                  : _getCurrentLocation,
                              icon: _isGettingLocation
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.green.shade700,
                                      ),
                                    )
                                  : Icon(Icons.my_location,
                                      size: 18, color: Colors.green.shade700),
                              label: Text(
                                _isGettingLocation
                                    ? 'Đang lấy vị trí...'
                                    : 'Lấy vị trí GPS hiện tại',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade50,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side:
                                      BorderSide(color: Colors.green.shade200),
                                ),
                              ),
                            ),
                          ),

                          // Coordinates
                          if (_latitude != null && _longitude != null)
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.gps_fixed,
                                      size: 18, color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Đã xác định',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Service radius card
                    _buildCard(
                      icon: Icons.radar,
                      title: 'Phạm vi nhận việc',
                      color: Colors.orange,
                      child: Column(
                        children: [
                          Text(
                            'Bạn sẽ nhận được yêu cầu từ khách hàng trong bán kính này',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 20),

                          // Radius display
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade50,
                                  Colors.amber.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Icon(Icons.radar,
                                        color: Colors.orange.shade700,
                                        size: 36),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${(_selectedRadius / 1000).toStringAsFixed(_selectedRadius % 1000 == 0 ? 0 : 1)}',
                                      style: TextStyle(
                                        fontSize: 52,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'km',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: Colors.orange.shade400,
                                    inactiveTrackColor: Colors.orange.shade100,
                                    thumbColor: Colors.orange.shade600,
                                    overlayColor:
                                        Colors.orange.withOpacity(0.2),
                                    trackHeight: 6,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 12),
                                  ),
                                  child: Slider(
                                    value: _selectedRadius.toDouble(),
                                    min: 1000,
                                    max: 40000,
                                    divisions: 39,
                                    onChanged: (v) => setState(
                                        () => _selectedRadius = v.round()),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('1 km',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange.shade700)),
                                      Text('40 km',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange.shade700)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quick select chips
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: _radiusOptions.map((r) {
                              final selected = _selectedRadius == r;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedRadius = r),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.orange.shade600
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: selected
                                          ? Colors.orange.shade600
                                          : Colors.grey.shade300,
                                      width: selected ? 2 : 1,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                                color: Colors.orange
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3))
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    '${r ~/ 1000} km',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_rounded, size: 22),
                                  SizedBox(width: 10),
                                  Text('Lưu thay đổi',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              // Avatar image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.primary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                      )
                    : _existingImageUrl != null
                        ? ClipOval(
                            child: Image.network(
                              _existingImageUrl!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 60,
                          ),
              ),
              // Edit button
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Nhấn để thay đổi ảnh đại diện',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // Card content
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
