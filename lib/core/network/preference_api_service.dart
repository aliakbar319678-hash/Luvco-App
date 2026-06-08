import 'package:dio/dio.dart';
import 'api_client.dart';
import 'auth_api_service.dart';

/// Service class for all `/users/me/preferences` endpoints.
///
/// Covers preset allergy tags, preset diet types, and CRUD for custom
/// allergies/diets.  Follows the same singleton pattern as [AuthApiService].
class PreferenceApiService {
  PreferenceApiService._internal();
  static final PreferenceApiService instance = PreferenceApiService._internal();

  final Dio _dio = ApiClient.instance.dio;

  /// Reuse the shared error handler from [AuthApiService].
  String _handleError(dynamic error) =>
      AuthApiService.instance.handleError(error);

  // ─────────────────────────────────────────────────────────────────
  //  GET  /users/me/preferences
  // ─────────────────────────────────────────────────────────────────

  /// Fetches the full preference profile for the authenticated user.
  ///
  /// Returns a map with keys: `allergyTags`, `customAllergies`,
  /// `dietTypes`, `customDiets`.
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await _dio.get('/users/me/preferences');
      return response.data['preferences'] as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  PUT  /users/me/preferences/allergies
  // ─────────────────────────────────────────────────────────────────

  /// Replaces the entire preset allergy-tags array.
  Future<List<dynamic>> replaceAllergyTags(List<String> tags) async {
    try {
      final response = await _dio.put(
        '/users/me/preferences/allergies',
        data: {'allergyTags': tags},
      );
      return response.data['allergyTags'] as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  PUT  /users/me/preferences/diets
  // ─────────────────────────────────────────────────────────────────

  /// Replaces the entire preset diet-types array.
  Future<List<dynamic>> replaceDietTypes(List<String> types) async {
    try {
      final response = await _dio.put(
        '/users/me/preferences/diets',
        data: {'dietTypes': types},
      );
      return response.data['dietTypes'] as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  POST  /users/me/preferences/allergies/custom
  // ─────────────────────────────────────────────────────────────────

  /// Appends a single custom allergy.
  Future<List<dynamic>> addCustomAllergy({
    required String name,
    required String type,
  }) async {
    try {
      final response = await _dio.post(
        '/users/me/preferences/allergies/custom',
        data: {'name': name, 'type': type},
      );
      return response.data['customAllergies'] as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  PUT  /users/me/preferences/allergies/custom
  // ─────────────────────────────────────────────────────────────────

  /// Bulk-replaces the entire custom allergies array.
  Future<List<dynamic>> replaceCustomAllergies(
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await _dio.put(
        '/users/me/preferences/allergies/custom',
        data: {'customAllergies': items},
      );
      return response.data['customAllergies'] as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  DELETE  /users/me/preferences/allergies/custom/{allergyId}
  // ─────────────────────────────────────────────────────────────────

  /// Removes a single custom allergy by its backend UUID.
  Future<List<dynamic>> deleteCustomAllergy(String allergyId) async {
    try {
      final response = await _dio.delete(
        '/users/me/preferences/allergies/custom/$allergyId',
      );
      return response.data['customAllergies'] as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  PATCH  /users/me/preferences/allergies/custom/{allergyId}
  // ─────────────────────────────────────────────────────────────────

  /// Partially updates a custom allergy (rename / toggle active).
  Future<List<dynamic>> patchCustomAllergy(
    String allergyId, {
    String? name,
    String? type,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (type != null) data['type'] = type;
      if (isActive != null) data['isActive'] = isActive;

      final response = await _dio.patch(
        '/users/me/preferences/allergies/custom/$allergyId',
        data: data,
      );
      return response.data['customAllergies'] as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  POST  /users/me/preferences/diets/custom
  // ─────────────────────────────────────────────────────────────────

  /// Appends a single custom diet.
  Future<List<dynamic>> addCustomDiet({required String name}) async {
    try {
      final response = await _dio.post(
        '/users/me/preferences/diets/custom',
        data: {'name': name},
      );
      return response.data['customDiets'] as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  PUT  /users/me/preferences/diets/custom
  // ─────────────────────────────────────────────────────────────────

  /// Bulk-replaces the entire custom diets array.
  Future<List<dynamic>> replaceCustomDiets(
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await _dio.put(
        '/users/me/preferences/diets/custom',
        data: {'customDiets': items},
      );
      return response.data['customDiets'] as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  DELETE  /users/me/preferences/diets/custom/{dietId}
  // ─────────────────────────────────────────────────────────────────

  /// Removes a single custom diet by its backend UUID.
  Future<List<dynamic>> deleteCustomDiet(String dietId) async {
    try {
      final response = await _dio.delete(
        '/users/me/preferences/diets/custom/$dietId',
      );
      return response.data['customDiets'] as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  PATCH  /users/me/preferences/diets/custom/{dietId}
  // ─────────────────────────────────────────────────────────────────

  /// Partially updates a custom diet (rename / toggle active).
  Future<List<dynamic>> patchCustomDiet(
    String dietId, {
    String? name,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (isActive != null) data['isActive'] = isActive;

      final response = await _dio.patch(
        '/users/me/preferences/diets/custom/$dietId',
        data: data,
      );
      return response.data['customDiets'] as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  GET  /content/onboarding  (preset tag lists for search modals)
  // ─────────────────────────────────────────────────────────────────

  /// Fetches the master list of preset allergy and diet tags for
  /// onboarding screens and search modals.
  Future<Map<String, List<String>>> getOnboardingTags() async {
    try {
      final response = await _dio.get('/content/onboarding');
      final data = response.data as Map<String, dynamic>;
      return {
        'allergies': List<String>.from(data['allergies'] ?? []),
        'diets': List<String>.from(data['diets'] ?? []),
      };
    } catch (e) {
      throw _handleError(e);
    }
  }
}
