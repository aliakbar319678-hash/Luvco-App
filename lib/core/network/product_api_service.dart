import 'package:dio/dio.dart';
import '../../models/product_model.dart';
import 'auth_api_service.dart';
import 'api_client.dart';

class ProductApiService {
  ProductApiService._internal();
  static final ProductApiService instance = ProductApiService._internal();

  final Dio _dio = ApiClient.instance.dio;

  String handleError(dynamic error) {
    return AuthApiService.instance.handleError(error);
  }

  /// GET /products/search
  /// Search products by text keyword query
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await _dio.get(
        '/products/search',
        queryParameters: {'q': query},
      );
      if (response.data['success'] == true && response.data['products'] != null) {
        final list = response.data['products'] as List;
        return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to search products');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// GET /products/{barcode}
  /// Retrieve product details by barcode
  Future<ProductModel> lookupProduct(String barcode) async {
    try {
      final response = await _dio.get('/products/$barcode');
      if (response.data['success'] == true && response.data['product'] != null) {
        return ProductModel.fromJson(response.data['product'] as Map<String, dynamic>);
      }
      throw Exception('Product not found');
    } catch (e) {
      throw handleError(e);
    }
  }
}
