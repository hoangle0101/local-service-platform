import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/provider_datasource.dart';
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

  // Step 2: Provider Details
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();

  bool _isCreatingProvider = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
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

      await providerDataSource.createProviderProfile(
        displayName: _displayNameController.text,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        skills: {'skills': skillsList},
        serviceRadiusM: 5000,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Provider profile created successfully!')),
        );
        context.go('/');
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
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? AppColors.white : AppColors.textSecondary,
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
              'Basic Information',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your account to get started',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              label: 'Full Name',
              hint: 'John Doe',
              controller: _fullNameController,
              prefixIcon: const Icon(Icons.person_outline),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Phone Number',
              hint: '+84987654321',
              type: TextFieldType.phone,
              controller: _phoneController,
              prefixIcon: const Icon(Icons.phone_outlined),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Password',
              hint: 'At least 6 characters',
              type: TextFieldType.password,
              controller: _passwordController,
              prefixIcon: const Icon(Icons.lock_outline),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Confirm Password',
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

        // OTP Input (simplified - you can use a proper OTP input widget)
        CustomTextField(
          label: 'Enter OTP',
          hint: '123456',
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
            // For now, just move to next step
            // In production, verify OTP via BLoC
            setState(() {
              _currentStep = 2;
            });
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
          'Tell us about your services',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          label: 'Display Name',
          hint: 'How you want to be known',
          controller: _displayNameController,
          prefixIcon: const Icon(Icons.badge_outlined),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a display name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Bio',
          hint: 'Tell customers about yourself',
          controller: _bioController,
          maxLines: 4,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Skills',
          hint: 'e.g., Plumbing, Electrical, Carpentry',
          controller: _skillsController,
          prefixIcon: const Icon(Icons.construction_outlined),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter at least one skill';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
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
}
