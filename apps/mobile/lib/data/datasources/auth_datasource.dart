import 'package:dio/dio.dart';
import '../../core/entities/auth_entities.dart';

enum OtpPurpose { login, resetPassword, verifyPhone }

class AuthDataSource {
  final Dio _dio;

  AuthDataSource()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://10.0.2.2:3000',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  // Register new user
  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'phone': phone,
        'password': password,
        'fullName': fullName,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  // Login with password
  Future<AuthTokens> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Handle wrapped response
        if (data.containsKey('data')) {
          return AuthTokens.fromJson(data['data'] as Map<String, dynamic>);
        }
        return AuthTokens.fromJson(data);
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  // Login with OTP
  Future<AuthTokens> loginWithOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _dio.post('/auth/login-otp', data: {
        'phone': phone,
        'code': code,
      });

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          return AuthTokens.fromJson(data['data'] as Map<String, dynamic>);
        }
        return AuthTokens.fromJson(data);
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to login with OTP: $e');
    }
  }

  // Send OTP
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    required OtpPurpose purpose,
  }) async {
    try {
      final purposeString = _otpPurposeToString(purpose);
      final response = await _dio.post('/auth/send-otp', data: {
        'phone': phone,
        'purpose': purposeString,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    required OtpPurpose purpose,
  }) async {
    try {
      final purposeString = _otpPurposeToString(purpose);
      final response = await _dio.post('/auth/verify-otp', data: {
        'phone': phone,
        'code': code,
        'purpose': purposeString,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Refresh token
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh-token', data: {
        'refreshToken': refreshToken,
      });

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          return data['data']['accessToken'] as String;
        }
        return data['accessToken'] as String;
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to refresh token: $e');
    }
  }

  // Logout
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {
        'refreshToken': refreshToken,
      });
    } catch (e) {
      // Logout is idempotent, so we don't throw error
      print('Logout error: $e');
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post('/auth/reset-password', data: {
        'phone': phone,
        'otp': otp,
        'newPassword': newPassword,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  String _otpPurposeToString(OtpPurpose purpose) {
    switch (purpose) {
      case OtpPurpose.login:
        return 'login';
      case OtpPurpose.resetPassword:
        return 'reset_password';
      case OtpPurpose.verifyPhone:
        return 'verify_phone';
    }
  }
}
