import 'package:dio/dio.dart';
import '../../models/content_model.dart';
import 'api_client.dart';
import 'auth_api_service.dart';

/// Service class containing all backend content endpoints.
class ContentApiService {
  ContentApiService._internal();
  static final ContentApiService instance = ContentApiService._internal();

  final Dio _dio = ApiClient.instance.dio;

  /// Reuse the shared error handler from [AuthApiService].
  String _handleError(dynamic error) =>
      AuthApiService.instance.handleError(error);

  /// GET /content/faq
  /// Retrieves seeded FAQ questions and answers.
  Future<List<FaqItem>> getFAQs() async {
    try {
      final response = await _dio.get('/content/faq');
      if (response.data['success'] == true && response.data['faqs'] != null) {
        final list = response.data['faqs'] as List;
        return list
            .map((item) => FaqItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load FAQs');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /content/privacy
  /// Retrieves the Luvco Privacy Policy document.
  Future<ContentDoc> getPrivacyPolicy() async {
    try {
      final response = await _dio.get('/content/privacy');
      if (response.data['success'] == true) {
        return ContentDoc.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to load Privacy Policy');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /content/terms
  /// Retrieves the Luvco Terms of Service document.
  Future<ContentDoc> getTermsOfService() async {
    try {
      final response = await _dio.get('/content/terms');
      if (response.data['success'] == true) {
        return ContentDoc.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to load Terms of Service');
    } catch (e) {
      throw _handleError(e);
    }
  }
}
