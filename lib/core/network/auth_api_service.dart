import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/auth/auth_response.dart';
import '../../models/auth/login_request.dart';
import '../../models/auth/register_request.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Service class containing all backend auth endpoints.
class AuthApiService {
  AuthApiService._internal();
  static final AuthApiService instance = AuthApiService._internal();

  final Dio _dio = ApiClient.instance.dio;

  /// Helper to extract server-provided error messages or throw generic ones.
  String handleError(dynamic error) {
    if (error is DioException) {
      dynamic data = error.response?.data;
      if (data is String && data.trim().isNotEmpty) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      if (data is Map) {
        if (data['message'] != null) {
          return data['message'].toString();
        }
        if (data['error'] != null && data['error'] is Map) {
          final errorObj = data['error'] as Map;
          final details = errorObj['details'];
          if (details != null && details is Map && details.isNotEmpty) {
            return details.values.join('\n');
          }
          if (errorObj['message'] != null) {
            return errorObj['message'].toString();
          }
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please check your network and try again.';
        case DioExceptionType.connectionError:
          // This fires when the device cannot reach the server.
          // Common causes:
          //  1. Backend server is not running (start it with: npm run dev)
          //  2. Wrong IP address in main.dart (use your PC\'s Wi-Fi IP, not 127.0.0.1)
          //  3. Phone and PC are not on the same Wi-Fi network
          return 'Cannot reach the server. Please ensure the backend is running.';
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          if (status == 401) return 'Invalid email or password.';
          if (status == 404) return 'Resource not found.';
          if (status == 500) return 'Server error. Please try again later.';
          return 'Server returned an error (code: $status).';
        default:
          return 'An unexpected network error occurred.';
      }
    }
    return error.toString();
  }

  /// POST /auth/register
  /// Creates a new user profile.
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /auth/verify-email
  /// Verifies user account using the 6-digit OTP code.
  Future<AuthResponse> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {'email': email, 'code': code},
      );
      final authResponse = AuthResponse.fromJson(response.data);
      if (authResponse.success &&
          authResponse.accessToken != null &&
          authResponse.refreshToken != null) {
        await TokenStorage.instance.saveTokens(
          accessToken: authResponse.accessToken!,
          refreshToken: authResponse.refreshToken!,
        );
      }
      return authResponse;
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /auth/login
  /// Authenticates user and stores credentials upon success.
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/auth/login', data: request.toJson());

      final authResponse = AuthResponse.fromJson(response.data);
      if (authResponse.success &&
          authResponse.accessToken != null &&
          authResponse.refreshToken != null) {
        await TokenStorage.instance.saveTokens(
          accessToken: authResponse.accessToken!,
          refreshToken: authResponse.refreshToken!,
        );
      }
      return authResponse;
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /auth/logout
  /// Invalidates and blacklists the user's refresh token.
  Future<AuthResponse> logout() async {
    try {
      final refreshToken = await TokenStorage.instance.getRefreshToken();
      if (refreshToken != null) {
        final response = await _dio.post(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
        await TokenStorage.instance.clearTokens();
        return AuthResponse.fromJson(response.data);
      }
      await TokenStorage.instance.clearTokens();
      return const AuthResponse(
        success: true,
        message: 'Successfully logged out.',
      );
    } catch (e) {
      await TokenStorage.instance.clearTokens();
      throw handleError(e);
    }
  }

  /// POST /auth/forgot-password
  /// Requests a password reset code.
  Future<AuthResponse> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /auth/verify-reset-code
  /// Verifies password reset OTP code.
  Future<AuthResponse> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-reset-code',
        data: {'email': email, 'code': code},
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /auth/reset-password
  /// Saves the new password using the validated OTP code.
  Future<AuthResponse> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw handleError(e);
    }
  }
}
