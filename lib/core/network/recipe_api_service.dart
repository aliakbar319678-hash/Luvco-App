import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/recipe_model.dart';
import '../../models/recipe_detail_model.dart';
import '../../models/recipe_ingredient_model.dart';
import '../../models/recipe_instruction_model.dart';
import '../../models/recipe_product_model.dart';
import 'auth_api_service.dart';
import 'api_client.dart';

class RecipeApiService {
  RecipeApiService._internal();
  static final RecipeApiService instance = RecipeApiService._internal();

  final Dio _dio = ApiClient.instance.dio;

  String handleError(dynamic error) {
    return AuthApiService.instance.handleError(error);
  }

  /// GET /recipes?filter={filter}
  /// Fetch recipes list (my-recipes, saved, public)
  Future<List<RecipeModel>> getRecipes(String filter) async {
    try {
      final response = await _dio.get(
        '/recipes',
        queryParameters: {'filter': filter},
      );
      if (response.data['success'] == true && response.data['recipes'] != null) {
        final list = response.data['recipes'] as List;
        return list.map((e) => RecipeModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to load recipes');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// GET /recipes/{id}
  /// Retrieve detailed recipe
  Future<RecipeDetailModel> getRecipe(String id, String currentUserId) async {
    try {
      final response = await _dio.get('/recipes/$id');
      if (response.data['success'] == true && response.data['recipe'] != null) {
        return RecipeDetailModel.fromJson(response.data['recipe'] as Map<String, dynamic>, currentUserId);
      }
      throw Exception('Failed to load recipe details');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /recipes
  /// Create a new recipe via the wizard
  Future<String> createRecipe(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/recipes', data: data);
      if (response.data['success'] == true && response.data['recipeId'] != null) {
        return response.data['recipeId'] as String;
      }
      throw Exception(response.data['message'] ?? 'Failed to create recipe');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// PUT /recipes/{id}
  /// Edit core properties of a recipe
  Future<void> editRecipe(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/recipes/$id', data: data);
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update recipe');
      }
    } catch (e) {
      throw handleError(e);
    }
  }

  /// DELETE /recipes/{id}
  /// Delete a recipe
  Future<void> deleteRecipe(String id) async {
    try {
      final response = await _dio.delete('/recipes/$id');
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete recipe');
      }
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /recipes/{id}/ingredients
  Future<RecipeIngredientModel> addIngredient(String recipeId, String description, int position) async {
    try {
      final response = await _dio.post(
        '/recipes/$recipeId/ingredients',
        data: {'description': description, 'position': position},
      );
      if (response.data['success'] == true && response.data['ingredient'] != null) {
        return RecipeIngredientModel.fromJson(response.data['ingredient']);
      }
      throw Exception('Failed to add ingredient');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// DELETE /recipes/{id}/ingredients/{ingredientId}
  Future<void> removeIngredient(String recipeId, String ingredientId) async {
    try {
      final response = await _dio.delete('/recipes/$recipeId/ingredients/$ingredientId');
      if (response.data['success'] != true) {
        throw Exception('Failed to remove ingredient');
      }
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /recipes/{id}/instructions
  Future<RecipeInstructionModel> addInstructionStep(String recipeId, String text, int stepNumber) async {
    try {
      final response = await _dio.post(
        '/recipes/$recipeId/instructions',
        data: {'text': text, 'stepNumber': stepNumber},
      );
      if (response.data['success'] == true && response.data['instruction'] != null) {
        return RecipeInstructionModel.fromJson(response.data['instruction']);
      }
      throw Exception('Failed to add instruction step');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// DELETE /recipes/{id}/instructions/{stepId}
  Future<void> removeInstructionStep(String recipeId, String stepId) async {
    try {
      final response = await _dio.delete('/recipes/$recipeId/instructions/$stepId');
      if (response.data['success'] != true) {
        throw Exception('Failed to remove instruction step');
      }
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /recipes/{id}/products
  Future<RecipeProductModel> addLinkedProduct(String recipeId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/recipes/$recipeId/products',
        data: data,
      );
      if (response.data['success'] == true && response.data['product'] != null) {
        return RecipeProductModel.fromJson(response.data['product']);
      }
      throw Exception('Failed to add product');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// DELETE /recipes/{id}/products/{productId}
  Future<void> removeLinkedProduct(String recipeId, String productId) async {
    try {
      final response = await _dio.delete('/recipes/$recipeId/products/$productId');
      if (response.data['success'] != true) {
        throw Exception('Failed to remove product');
      }
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /recipes/{id}/save
  Future<void> saveRecipe(String id) async {
    try {
      final response = await _dio.post('/recipes/$id/save');
      if (response.data['success'] != true) {
        throw Exception('Failed to save recipe');
      }
    } catch (e) {
      throw handleError(e);
    }
  }

  /// DELETE /recipes/{id}/save
  Future<void> unsaveRecipe(String id) async {
    try {
      final response = await _dio.delete('/recipes/$id/save');
      if (response.data['success'] != true) {
        throw Exception('Failed to unsave recipe');
      }
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Two-stage image upload helper (cover-upload-url + PUT to URL)
  Future<String> uploadRecipeCover(File imageFile, String fileName) async {
    try {
      String mimeType = 'image/jpeg';
      final ext = fileName.split('.').last.toLowerCase();
      if (ext == 'png') mimeType = 'image/png';

      // 1. Get presigned upload URL details
      final urlResponse = await _dio.get(
        '/recipes/cover-upload-url',
        queryParameters: {
          'fileName': fileName,
          'mimeType': mimeType,
        },
      );

      if (urlResponse.data['success'] != true) {
        throw Exception('Failed to get cover image upload URL');
      }

      final isLocal = urlResponse.data['isLocal'] as bool? ?? false;
      final fileUrl = urlResponse.data['fileUrl'] as String;
      final key = urlResponse.data['key'] as String;

      if (isLocal) {
        // Local upload fallback: use authenticated _dio with relative URL
        final uploadResponse = await _dio.put(
          '/users/me/profile-picture/local-upload',
          queryParameters: {'key': key},
          data: await imageFile.readAsBytes(),
          options: Options(
            headers: {
              'Content-Type': 'application/octet-stream',
            },
          ),
        );
        if (uploadResponse.data['success'] == true) {
          return fileUrl;
        }
      } else {
        // S3 absolute URL upload: use fresh Dio to prevent sending Bearer token
        final uploadUrl = urlResponse.data['uploadUrl'] as String;
        final uploadDio = Dio();
        final uploadResponse = await uploadDio.put(
          uploadUrl,
          data: await imageFile.readAsBytes(),
          options: Options(
            headers: {
              'Content-Type': 'application/octet-stream',
            },
          ),
        );
        if (uploadResponse.statusCode == 200) {
          return fileUrl;
        }
      }
      throw Exception('Failed to upload recipe cover image');
    } catch (e) {
      throw handleError(e);
    }
  }
}
