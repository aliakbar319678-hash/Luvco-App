import 'package:dio/dio.dart';
import 'auth_api_service.dart';
import 'api_client.dart';

/// Service class containing all backend favorites endpoints.
class FavoriteApiService {
  FavoriteApiService._internal();
  static final FavoriteApiService instance = FavoriteApiService._internal();

  final Dio _dio = ApiClient.instance.dio;

  /// Helper to extract server-provided error messages or throw generic ones.
  String handleError(dynamic error) {
    return AuthApiService.instance.handleError(error);
  }

  /// GET /favorites
  /// Retrieve list of favorite products for the authenticated user.
  Future<List<dynamic>> getFavorites() async {
    try {
      final response = await _dio.get('/favorites');
      if (response.data['success'] == true && response.data['favorites'] != null) {
        return response.data['favorites'] as List;
      }
      throw Exception('Failed to fetch favorites');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /favorites
  /// Add a product to favorites.
  Future<Map<String, dynamic>> addFavorite({
    required String barcode,
    required String productName,
    String? productImageUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/favorites',
        data: {
          'barcode': barcode,
          'productName': productName,
          'productImageUrl': productImageUrl,
        },
      );
      if (response.data['success'] == true && response.data['favorite'] != null) {
        return response.data['favorite'] as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to add favorite');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// DELETE /favorites/{barcode}
  /// Remove a product from favorites by barcode.
  Future<void> deleteFavorite(String barcode) async {
    try {
      final response = await _dio.delete('/favorites/$barcode');
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete favorite');
      }
    } catch (e) {
      throw handleError(e);
    }
  }
}
