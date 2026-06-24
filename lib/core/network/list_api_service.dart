import 'package:dio/dio.dart';
import '../../models/shopping_list_model.dart';
import 'auth_api_service.dart';
import 'api_client.dart';

class ListApiService {
  ListApiService._internal();
  static final ListApiService instance = ListApiService._internal();

  final Dio _dio = ApiClient.instance.dio;

  String handleError(dynamic error) {
    return AuthApiService.instance.handleError(error);
  }

  /// GET /lists
  /// Retrieve all shopping lists belonging to the user
  Future<List<ShoppingListModel>> getLists() async {
    try {
      final response = await _dio.get('/lists');
      if (response.data['success'] == true && response.data['lists'] != null) {
        final list = response.data['lists'] as List;
        return list.map((e) => ShoppingListModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to load shopping lists');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// GET /lists/{id}
  /// Retrieve shopping list details and item list by list ID
  Future<Map<String, dynamic>> getList(String id) async {
    try {
      final response = await _dio.get('/lists/$id');
      if (response.data['success'] == true && response.data['list'] != null) {
        return response.data['list'] as Map<String, dynamic>;
      }
      throw Exception('Failed to load shopping list details');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /lists
  /// Create a new shopping list
  Future<ShoppingListModel> createList(String title) async {
    try {
      final response = await _dio.post(
        '/lists',
        data: {'title': title},
      );
      if (response.data['success'] == true && response.data['list'] != null) {
        return ShoppingListModel.fromJson(response.data['list'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to create shopping list');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// PATCH /lists/{id}
  /// Edit an existing shopping list's title and/or description
  Future<ShoppingListModel> editList(String id, {String? title, String? description}) async {
    try {
      final payload = <String, dynamic>{};
      if (title != null) payload['title'] = title;
      if (description != null) payload['description'] = description;
      final response = await _dio.patch('/lists/$id', data: payload);
      if (response.data['success'] == true && response.data['list'] != null) {
        return ShoppingListModel.fromJson(response.data['list'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to edit shopping list');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// DELETE /lists/{id}
  /// Delete a shopping list and cascade-delete all its items
  Future<void> deleteList(String id) async {
    try {
      final response = await _dio.delete('/lists/$id');
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete shopping list');
      }
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /lists/{id}/duplicate
  /// Duplicate an entire shopping list and all its items as a new list
  Future<ShoppingListModel> duplicateList(String id) async {
    try {
      final response = await _dio.post('/lists/$id/duplicate');
      if (response.data['success'] == true && response.data['list'] != null) {
        return ShoppingListModel.fromJson(response.data['list'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'Failed to duplicate shopping list');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST /lists/{id}/items
  /// Add a product item to a shopping list
  Future<Map<String, dynamic>> addItem(
    String listId, {
    String? barcode,
    String? productName,
    String? productImageUrl,
    int? quantity,
    String? unit,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (barcode != null) payload['barcode'] = barcode;
      if (productName != null) payload['productName'] = productName;
      if (productImageUrl != null) payload['productImageUrl'] = productImageUrl;
      if (quantity != null) payload['quantity'] = quantity;
      if (unit != null) payload['unit'] = unit;

      final response = await _dio.post(
        '/lists/$listId/items',
        data: payload,
      );
      if (response.data['success'] == true && response.data['item'] != null) {
        return response.data['item'] as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to add item to shopping list');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// PUT /lists/{listId}/items/{itemId}
  /// Update details of a shopping list item (quantity, check/uncheck, order position)
  Future<Map<String, dynamic>> editItem(
    String listId,
    String itemId, {
    int? quantity,
    String? unit,
    bool? isChecked,
    int? position,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (quantity != null) payload['quantity'] = quantity;
      if (unit != null) payload['unit'] = unit;
      if (isChecked != null) payload['isChecked'] = isChecked;
      if (position != null) payload['position'] = position;

      final response = await _dio.put(
        '/lists/$listId/items/$itemId',
        data: payload,
      );
      if (response.data['success'] == true && response.data['item'] != null) {
        return response.data['item'] as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to update shopping list item');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// DELETE /lists/{listId}/items/{itemId}
  /// Remove an item from a shopping list
  Future<void> removeItem(String listId, String itemId) async {
    try {
      final response = await _dio.delete('/lists/$listId/items/$itemId');
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to remove item from shopping list');
      }
    } catch (e) {
      throw handleError(e);
    }
  }
}
