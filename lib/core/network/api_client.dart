import 'package:dio/dio.dart';
import 'token_storage.dart';

/// A professional Dio API client featuring secure token inclusion
/// and queued automatic token refreshing on 401 Unauthorized errors.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Check if this error came from the refresh-token endpoint itself
            if (error.requestOptions.path == '/auth/refresh-token') {
              await TokenStorage.instance.clearTokens();
              return handler.next(error);
            }

            final refreshToken = await TokenStorage.instance.getRefreshToken();
            if (refreshToken != null) {
              try {
                // Request a new access token
                final newAccessToken = await _refreshAccessToken(refreshToken);
                if (newAccessToken != null) {
                  // Retry the original request with the new token
                  final options = error.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newAccessToken';

                  // Clone request and perform again
                  final response = await _dio.fetch(options);
                  return handler.resolve(response);
                }
              } catch (e) {
                // Refresh failed, wipe tokens
                await TokenStorage.instance.clearTokens();
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;

  // For Android emulator use 10.0.2.2, for iOS simulator use localhost.
  // For physical devices, use your computer's local network IP (e.g. 192.168.1.x)
  // OR use 127.0.0.1 if using adb reverse tcp:3000 tcp:3000
  String _baseUrl = 'http://127.0.0.1:3000/api/v1';

  /// Updates the Base URL for the client.
  void setBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  /// Request a new access token using a persistent refresh token.
  Future<String?> _refreshAccessToken(String refreshToken) async {
    try {
      // Create a separate dio instance to avoid interceptor recursion/deadlocks
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success) {
          final newAccessToken = response.data['accessToken'] as String?;
          if (newAccessToken != null) {
            await TokenStorage.instance.saveAccessToken(newAccessToken);
            return newAccessToken;
          }
        }
      }
    } catch (_) {
      rethrow;
    }
    return null;
  }
}
