import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/provider_datasource.dart';
import '../../../data/datasources/auth_datasource.dart';
import '../../../data/storage/secure_storage.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/minimalist_widgets.dart';

class RegisterProviderScreen extends StatefulWidget {
  const RegisterProviderScreen({super.key});

  @override
  State<RegisterProviderScreen> createState() => _RegisterProviderScreenState();
}

class _RegisterProviderScreenState extends State<RegisterProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 0: Tài khoản
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 1: Xác thực OTP
  final _otpController = TextEditingController();

  // Step 2: Hồ sơ đối tác
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceYearsController = TextEditingController();

  // Location & Service
  double _latitude = 21.0285;
  double _longitude = 105.8542;
  double _serviceRadius = 10; // km
  bool _isCreatingProvider = false;
  bool _acceptsTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _addressController.dispose();
    _experienceYearsController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã cập nhật vị trí hiện tại'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        String phone = _phoneController.text.trim();
        if (!phone.startsWith('+')) {
          if (phone.startsWith('0')) {
            phone = '+84${phone.substring(1)}';
          } else if (phone.startsWith('84')) {
            phone = '+$phone';
          } else {
            phone = '+84$phone';
          }
        }
        if (_displayNameController.text.isEmpty) {
          _displayNameController.text = _fullNameController.text;
        }
        context.read<AuthBloc>().add(
              RegisterRequested(
                phone: phone,
                password: _passwordController.text,
                fullName: _fullNameController.text,
              ),
            );
      }
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        context.read<AuthBloc>().add(
              OtpVerifyRequested(
                phone: _phoneController.text,
                code: _otpController.text,
                purpose: 'verify_phone',
              ),
            );
      }
    }
  }

  Future<void> _createProviderProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptsTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chấp nhận Điều khoản dịch vụ'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCreatingProvider = true);

    try {
      final providerDataSource = ProviderDataSource();
      final skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      var token = await SecureStorage.getAccessToken();
      if (token == null) {
        final authDataSource = AuthDataSource();
        String phone = _phoneController.text.trim();
        if (!phone.startsWith('+'))
          phone = '+84${phone.substring(phone.startsWith('0') ? 1 : 0)}';
        final tokens = await authDataSource.login(
            phone: phone, password: _passwordController.text);
        await SecureStorage.saveAuthData(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            userPhone: phone);
        token = tokens.accessToken;
      }

      await providerDataSource.createProviderProfile(
        displayName: _displayNameController.text,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        skills: skillsList,
        serviceRadiusM: (_serviceRadius * 1000).toInt(),
        latitude: _latitude,
        longitude: _longitude,
        address:
            _addressController.text.isNotEmpty ? _addressController.text : null,
      );

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi khi tạo hồ sơ: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingProvider = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 64),
            ),
            const SizedBox(height: 24),
            Text('Chúc mừng đối tác!',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 12),
            const Text(
              'Hồ sơ của bạn đã được tạo thành công. Bạn có thể bắt đầu nhận lịch ngay bây giờ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            MinButton(
              text: 'Đi đến Trang chủ',
              isFullWidth: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/provider/home');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () =>
              _currentStep > 0 ? setState(() => _currentStep--) : context.pop(),
        ),
        title: Text(
          'Đăng ký Đối tác',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is RegistrationSuccess) {
            setState(() => _currentStep = 1);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating),
            );
          } else if (state is OtpVerified) {
            setState(() => _currentStep = 2);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating),
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Form(key: _formKey, child: _buildStepContent()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        children: [
          _buildStepNode(0, 'Tài khoản'),
          _buildStepLink(0),
          _buildStepNode(1, 'Xác thực'),
          _buildStepLink(1),
          _buildStepNode(2, 'Hồ sơ'),
        ],
      ),
    );
  }

  Widget _buildStepNode(int step, String label) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color:
                isActive || isCompleted ? AppColors.primary : AppColors.shelf,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isCompleted
                  ? AppColors.primary
                  : AppColors.borderLight,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: AppColors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color:
                          isActive ? AppColors.white : AppColors.textTertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight:
                isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
            color: isActive || isCompleted
                ? AppColors.primary
                : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLink(int step) {
    bool isCompleted = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: isCompleted ? AppColors.primary : AppColors.shelf,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildDetailsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin cơ bản',
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 12),
        const Text('Hãy bắt đầu bằng việc tạo tài khoản cho bạn.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        MinTextField(
          label: 'Họ và tên',
          hint: 'Vd: Nguyễn Văn A',
          controller: _fullNameController,
          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Vui lòng nhập họ tên' : null,
        ),
        const SizedBox(height: 24),
        MinTextField(
          label: 'Số điện thoại',
          hint: 'Vd: 0912345678',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
          validator: (v) => (v == null || v.length < 10)
              ? 'Số điện thoại không hợp lệ'
              : null,
        ),
        const SizedBox(height: 24),
        MinTextField(
          label: 'Mật khẩu',
          hint: 'Tối thiểu 6 ký tự',
          obscureText: true,
          controller: _passwordController,
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          validator: (v) =>
              (v == null || v.length < 6) ? 'Mật khẩu quá ngắn' : null,
        ),
        const SizedBox(height: 24),
        MinTextField(
          label: 'Xác nhận mật khẩu',
          hint: 'Nhập lại mật khẩu',
          obscureText: true,
          controller: _confirmPasswordController,
          prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
          validator: (v) =>
              (v != _passwordController.text) ? 'Mật khẩu không khớp' : null,
        ),
        const SizedBox(height: 40),
        MinButton(
          text: 'Tiếp tục',
          isFullWidth: true,
          onPressed: _handleNext,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Xác thực số điện thoại',
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 12),
        Text('Chúng tôi đã gửi mã OTP đến ${_phoneController.text}',
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        MinTextField(
          label: 'Mã xác thực (6 số)',
          hint: '123456',
          controller: _otpController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.security_rounded, size: 20),
          validator: (v) => (v?.length != 6) ? 'Mã OTP phải có 6 chữ số' : null,
        ),
        const SizedBox(height: 40),
        MinButton(
            text: 'Xác nhận OTP', isFullWidth: true, onPressed: _handleNext),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => context.read<AuthBloc>().add(OtpSendRequested(
                phone: _phoneController.text, purpose: 'verify_phone')),
            child: const Text('Gửi lại mã OTP',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hồ sơ chuyên nghiệp',
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 12),
        const Text(
            'Cung cấp thêm thông tin để khách hàng có thể tìm thấy bạn dễ dàng hơn.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        MinTextField(
          label: 'Tên hiển thị (Tên cửa hàng/cá nhân) *',
          hint: 'Vd: Điện lạnh Bách Khoa',
          controller: _displayNameController,
          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Vui lòng nhập tên hiển thị' : null,
        ),
        const SizedBox(height: 24),
        MinTextField(
          label: 'Giới thiệu ngắn',
          hint: 'Vd: Chuyên sửa chữa điều hòa, tủ lạnh tại nhà...',
          controller: _bioController,
          prefixIcon: const Icon(Icons.description_outlined, size: 20),
        ),
        const SizedBox(height: 24),
        MinTextField(
          label: 'Kỹ năng / Dịch vụ *',
          hint: 'Vd: Sửa điện, Sửa nước, Vệ sinh...',
          controller: _skillsController,
          prefixIcon: const Icon(Icons.handyman_outlined, size: 20),
          validator: (v) => (v == null || v.isEmpty)
              ? 'Vui lòng nhập ít nhất một kỹ năng'
              : null,
        ),
        const SizedBox(height: 8),
        const Text('Mẹo: Ngắt quãng bằng dấu phẩy (,)',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.map_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text('Khu vực hoạt động',
                style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
        const SizedBox(height: 20),
        MinTextField(
          label: 'Địa chỉ hoạt động',
          hint: 'Nhập địa chỉ của bạn',
          controller: _addressController,
          prefixIcon: const Icon(Icons.location_pin, size: 20),
          suffixIcon: IconButton(
              icon: const Icon(Icons.my_location_rounded,
                  color: AppColors.primary, size: 20),
              onPressed: _getCurrentLocation),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bán kính phục vụ',
                style: TextStyle(fontWeight: FontWeight.w600)),
            Text('${_serviceRadius.toInt()} km',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: _serviceRadius,
          min: 1,
          max: 50,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.shelf,
          onChanged: (v) => setState(() => _serviceRadius = v),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Checkbox(
              value: _acceptsTerms,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              onChanged: (v) => setState(() => _acceptsTerms = v ?? false),
            ),
            Expanded(
              child: Text(
                'Tôi chấp nhận Điều khoản và Quy định của nền tảng đối tác.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        MinButton(
          text: 'Hoàn tất đăng ký',
          isLoading: _isCreatingProvider,
          isFullWidth: true,
          onPressed: _createProviderProfile,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
