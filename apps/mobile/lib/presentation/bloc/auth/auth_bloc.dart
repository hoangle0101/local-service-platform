import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/auth_datasource.dart';
import '../../../data/storage/secure_storage.dart';
import '../../../core/entities/auth_entities.dart';
import 'auth_event.dart';

export 'auth_event.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthDataSource _authDataSource;

  AuthBloc({AuthDataSource? authDataSource})
      : _authDataSource = authDataSource ?? AuthDataSource(),
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<LoginWithOtpRequested>(_onLoginWithOtpRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<OtpSendRequested>(_onOtpSendRequested);
    on<OtpVerifyRequested>(_onOtpVerifyRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isAuth = await SecureStorage.isAuthenticated();
    if (isAuth) {
      final accessToken = await SecureStorage.getAccessToken();
      final refreshToken = await SecureStorage.getRefreshToken();
      if (accessToken != null && refreshToken != null) {
        emit(Authenticated(
          tokens: AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        ));
        return;
      }
    }
    emit(Unauthenticated());
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final tokens = await _authDataSource.login(
        phone: event.phone,
        password: event.password,
      );

      await SecureStorage.saveAuthData(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userPhone: event.phone,
      );

      emit(Authenticated(tokens: tokens));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onLoginWithOtpRequested(
    LoginWithOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final tokens = await _authDataSource.loginWithOtp(
        phone: event.phone,
        code: event.code,
      );

      await SecureStorage.saveAuthData(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userPhone: event.phone,
      );

      emit(Authenticated(tokens: tokens));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _authDataSource.register(
        phone: event.phone,
        password: event.password,
        fullName: event.fullName,
      );

      emit(RegistrationSuccess(
        message: result['message'] as String? ??
            'Registration successful. Please verify OTP.',
        phone: event.phone,
      ));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onOtpSendRequested(
    OtpSendRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final purpose = _stringToOtpPurpose(event.purpose);
      final result = await _authDataSource.sendOtp(
        phone: event.phone,
        purpose: purpose,
      );

      emit(OtpSent(
        message: result['message'] as String? ?? 'OTP sent successfully',
        phone: event.phone,
        code: result['code'] as String?, // Only in development
      ));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onOtpVerifyRequested(
    OtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final purpose = _stringToOtpPurpose(event.purpose);
      final result = await _authDataSource.verifyOtp(
        phone: event.phone,
        code: event.code,
        purpose: purpose,
      );

      emit(OtpVerified(
        result['message'] as String? ?? 'OTP verified successfully',
      ));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken != null) {
        await _authDataSource.logout(refreshToken);
      }
      await SecureStorage.clearAuthData();
      emit(Unauthenticated());
    } catch (e) {
      // Even if logout fails, clear local data
      await SecureStorage.clearAuthData();
      emit(Unauthenticated());
    }
  }

  String _extractErrorMessage(dynamic error) {
    final errorString = error.toString();
    if (errorString.contains('Exception:')) {
      return errorString.replaceAll('Exception:', '').trim();
    }
    return 'An error occurred. Please try again.';
  }

  OtpPurpose _stringToOtpPurpose(String purpose) {
    switch (purpose.toLowerCase()) {
      case 'login':
        return OtpPurpose.login;
      case 'reset_password':
        return OtpPurpose.resetPassword;
      case 'verify_phone':
        return OtpPurpose.verifyPhone;
      default:
        return OtpPurpose.verifyPhone;
    }
  }
}
