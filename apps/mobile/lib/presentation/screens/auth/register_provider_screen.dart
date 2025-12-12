import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/provider_datasource.dart';
import '../../../data/datasources/auth_datasource.dart';
import '../../../data/storage/secure_storage.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/atoms/custom_button.dart';
import '../../widgets/atoms/custom_text_field.dart';

class RegisterProviderScreen extends StatefulWidget {
  const RegisterProviderScreen({super.key});

  @override
  State<RegisterProviderScreen> createState() => _RegisterProviderScreenState();
}

class _RegisterProviderScreenState extends State<RegisterProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1: Basic Info
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 2: OTP
  final _otpController = TextEditingController();

  // Step 3: Provider Details
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceYearsController = TextEditingController();

  // Location
  double _latitude = 21.0285; // Default Hanoi
  double _longitude = 105.8542;

  // Service Radius
  double _serviceRadius = 5; // km

  // Working Hours
  TimeOfDay _workStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _workEndTime = const TimeOfDay(hour: 18, minute: 0);
  final List<String> _workingDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

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

  void _handleNext() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        // Format phone number with +84 if not present
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

        // Pre-fill display name from full name
        if (_displayNameController.text.isEmpty) {
          _displayNameController.text = _fullNameController.text;
        }

        // Register user account
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
        setState(() {
          _currentStep = 2;
        });
      }
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _createProviderProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptsTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingProvider = true;
    });

    try {
      final providerDataSource = ProviderDataSource();

      // Parse skills from comma-separated string
      final skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Check if we have a valid token
      var token = await SecureStorage.getAccessToken();

      // If no token, try to login with the credentials we have
      if (token == null) {
        print('⚠️ No access token found. Attempting explicit login...');
        try {
          final authDataSource = AuthDataSource();
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

          final tokens = await authDataSource.login(
            phone: phone,
            password: _passwordController.text,
          );

          await SecureStorage.saveAuthData(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            userPhone: phone,
          );

          token = tokens.accessToken;
          print('✅ Explicit login successful. Token obtained.');
        } catch (e) {
          print('❌ Explicit login failed: $e');
          throw Exception(
              'Authentication failed. Please try logging in again.');
        }
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

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create provider profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingProvider = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
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
              'Welcome, Provider!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your provider profile has been created successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              '• Add your services to start receiving bookings\n• Set your availability\n• Complete your profile',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/provider/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Provider'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is RegistrationSuccess) {
            // Move to OTP verification step
            setState(() {
              _currentStep = 1;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is OtpVerified) {
            // Move to provider details step
            setState(() {
              _currentStep = 2;
            });
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: _buildStepContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Account'),
          _buildStepLine(0),
          _buildStepIndicator(1, 'Verify'),
          _buildStepLine(1),
          _buildStepIndicator(2, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryDark : AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isActive && _currentStep > step
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive
                            ? AppColors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: isActive
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isActive ? AppColors.primaryDark : AppColors.borderLight,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildOtpVerificationStep();
      case 2:
        return _buildProviderDetailsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBasicInfoStep() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Your Account',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your personal information',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              label: 'Full Name *',
              hint: 'Nguyễn Văn A',
              controller: _fullNameController,
              prefixIcon: const Icon(Icons.person_outline),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Full name is required';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Phone Number *',
              hint: '0987654321',
              type: TextFieldType.phone,
              controller: _phoneController,
              prefixIcon: const Icon(Icons.phone_outlined),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                // Remove any formatting
                final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
                if (cleaned.length < 9) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Password *',
              hint: 'At least 6 characters',
              type: TextFieldType.password,
              controller: _passwordController,
              prefixIcon: const Icon(Icons.lock_outline),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Confirm Password *',
              hint: 'Re-enter your password',
              type: TextFieldType.password,
              controller: _confirmPasswordController,
              prefixIcon: const Icon(Icons.lock_outline),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Continue',
              onPressed: isLoading ? null : _handleNext,
              isLoading: isLoading,
              isFullWidth: true,
              size: ButtonSize.large,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? '),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Login'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOtpVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verify Your Phone',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve sent an OTP to ${_phoneController.text}',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 32),

        // OTP Input
        CustomTextField(
          label: 'Enter OTP',
          hint: '123456',
          controller: _otpController,
          type: TextFieldType.number,
          maxLength: 6,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the OTP';
            }
            if (value.length != 6) {
              return 'OTP must be 6 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),

        CustomButton(
          text: 'Verify OTP',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              context.read<AuthBloc>().add(
                    OtpVerifyRequested(
                      phone: _phoneController.text,
                      code: _otpController.text,
                      purpose: 'verify_phone',
                    ),
                  );
            }
          },
          isFullWidth: true,
          size: ButtonSize.large,
        ),

        const SizedBox(height: 16),

        CustomButton(
          text: 'Resend OTP',
          variant: ButtonVariant.text,
          onPressed: () {
            context.read<AuthBloc>().add(
                  OtpSendRequested(
                    phone: _phoneController.text,
                    purpose: 'verify_phone',
                  ),
                );
          },
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildProviderDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Provider Profile',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Complete your professional profile',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 24),

        // Display Name
        CustomTextField(
          label: 'Display Name *',
          hint: 'How customers will see you',
          controller: _displayNameController,
          prefixIcon: const Icon(Icons.badge_outlined),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Display name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Bio
        CustomTextField(
          label: 'About You',
          hint: 'Describe your experience and expertise...',
          controller: _bioController,
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Skills
        CustomTextField(
          label: 'Skills *',
          hint: 'e.g., Plumbing, Electrical, AC Repair',
          controller: _skillsController,
          prefixIcon: const Icon(Icons.construction_outlined),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter at least one skill';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Separate multiple skills with commas',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // Location Section
        const Row(
          children: [
            Icon(Icons.location_on, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Service Location',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),

        CustomTextField(
          label: 'Work Address',
          hint: 'Your base location for services',
          controller: _addressController,
          prefixIcon: const Icon(Icons.home_work_outlined),
          suffixIcon: IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.primary),
            onPressed: _getCurrentLocation,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.gps_fixed, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'GPS: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Service Radius
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Service Radius'),
            Text(
              '${_serviceRadius.toInt()} km',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
        Slider(
          value: _serviceRadius,
          min: 1,
          max: 50,
          divisions: 49,
          activeColor: AppColors.primary,
          onChanged: (value) {
            setState(() {
              _serviceRadius = value;
            });
          },
        ),
        Text(
          'You will receive booking requests within this radius',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // Working Hours
        const Row(
          children: [
            Icon(Icons.schedule, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Working Hours',
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
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _workStartTime,
                  );
                  if (time != null) {
                    setState(() => _workStartTime = time);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade600)),
                          Text(_workStartTime.format(context),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
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
                    initialTime: _workEndTime,
                  );
                  if (time != null) {
                    setState(() => _workEndTime = time);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('End',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade600)),
                          Text(_workEndTime.format(context),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Working Days
        const Text('Working Days'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
            final isSelected = _workingDays.contains(day);
            return FilterChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _workingDays.add(day);
                  } else {
                    _workingDays.remove(day);
                  }
                });
              },
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primaryDark,
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Terms of Service
        CheckboxListTile(
          value: _acceptsTerms,
          onChanged: (value) {
            setState(() {
              _acceptsTerms = value ?? false;
            });
          },
          title: const Text(
            'I agree to the Terms of Service and Privacy Policy',
            style: TextStyle(fontSize: 14),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 24),

        CustomButton(
          text: 'Create Provider Profile',
          onPressed: _isCreatingProvider ? null : _createProviderProfile,
          isLoading: _isCreatingProvider,
          isFullWidth: true,
          size: ButtonSize.large,
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Back',
          variant: ButtonVariant.outline,
          onPressed: _handleBack,
          isFullWidth: true,
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
}
