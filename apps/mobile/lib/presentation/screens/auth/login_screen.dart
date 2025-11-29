import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/atoms/custom_button.dart';
import '../../widgets/atoms/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _useOtp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
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

      if (_useOtp) {
        // Send OTP
        context.read<AuthBloc>().add(
              OtpSendRequested(
                phone: phone,
                purpose: 'login',
              ),
            );
      } else {
        // Login with password
        context.read<AuthBloc>().add(
              LoginRequested(
                phone: phone,
                password: _passwordController.text,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // Navigate based on user role
            if (state.user != null) {
              if (state.user!.isProvider) {
                context.go('/provider/home');
              } else {
                context.go('/user/home');
              }
            } else {
              // Fallback to guest home if no user data
              context.go('/');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login successful!')),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is OtpSent) {
            // Navigate to OTP verification
            context.push('/verify-otp', extra: {
              'phone': state.phone,
              'purpose': 'login',
              'code': state.code, // For development
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.home_repair_service,
                        size: 40,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login to continue',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 40),

                    // Phone Number
                    CustomTextField(
                      label: 'Phone Number',
                      hint: '0987654321 or +84987654321',
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

                    // Password (only if not using OTP)
                    if (!_useOtp) ...[
                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        type: TextFieldType.password,
                        controller: _passwordController,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Login Button
                    CustomButton(
                      text: _useOtp ? 'Send OTP' : 'Login',
                      onPressed: isLoading ? null : _handleLogin,
                      isLoading: isLoading,
                      isFullWidth: true,
                      size: ButtonSize.large,
                    ),

                    const SizedBox(height: 16),

                    // Toggle OTP/Password
                    CustomButton(
                      text: _useOtp ? 'Use Password Instead' : 'Login with OTP',
                      variant: ButtonVariant.outline,
                      onPressed: () {
                        setState(() {
                          _useOtp = !_useOtp;
                        });
                      },
                      isFullWidth: true,
                    ),

                    const SizedBox(height: 32),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('/register/role');
                          },
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
