import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/list_api_service.dart';

// ── A single product item inside a shopping list ─────────────────
class ShoppingListItem {
  final String id;
  final String name;
  final String description;
  final String? thumbnailAsset;
  final bool isChecked;
  final String? barcode;
  final int quantity;
  final String? unit;
  final int position;

  const ShoppingListItem({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnailAsset,
    this.isChecked = false,
    this.barcode,
    this.quantity = 1,
    this.unit,
    this.position = 0,
  });

  ShoppingListItem copyWith({
    String? id,
    String? name,
    String? description,
    String? thumbnailAsset,
    bool? isChecked,
    String? barcode,
    int? quantity,
    String? unit,
    int? position,
  }) =>
      ShoppingListItem(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        thumbnailAsset: thumbnailAsset ?? this.thumbnailAsset,
        isChecked: isChecked ?? this.isChecked,
        barcode: barcode ?? this.barcode,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        position: position ?? this.position,
      );

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    final barcode = json['barcode'] as String?;
    final name = json['productName'] as String? ?? 'Product';
    final quantity = json['quantity'] as int? ?? 1;
    final unit = json['unit'] as String?;
    final position = json['position'] as int? ?? 0;
    final isChecked = json['isChecked'] as bool? ?? false;
    final imageUrl = json['productImageUrl'] as String? ?? '';

    // Description can format the quantity and unit
    final description = unit != null && unit.isNotEmpty
        ? 'Quantity: $quantity $unit'
        : 'Quantity: $quantity';

    return ShoppingListItem(
      id: json['id'] as String,
      name: name,
      description: description,
      thumbnailAsset: imageUrl.isNotEmpty ? imageUrl : null,
      isChecked: isChecked,
      barcode: barcode,
      quantity: quantity,
      unit: unit,
      position: position,
    );
  }
}

// ── Per-list state: holds items for one shopping list ─────────────
class ShoppingListDetailState {
  final String listId;
  final List<ShoppingListItem> items;

  const ShoppingListDetailState({
    required this.listId,
    required this.items,
  });

  ShoppingListDetailState copyWith({
    String? listId,
    List<ShoppingListItem>? items,
  }) =>
      ShoppingListDetailState(
        listId: listId ?? this.listId,
        items: items ?? this.items,
      );
}

class ShoppingListDetailNotifier
    extends StateNotifier<ShoppingListDetailState> {
  final String listId;

  ShoppingListDetailNotifier(this.listId)
      : super(ShoppingListDetailState(
          listId: listId,
          items: const [],
        )) {
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      final data = await ListApiService.instance.getList(listId);
      if (data['items'] != null && data['items'] is List) {
        final listItems = (data['items'] as List)
            .map((e) => ShoppingListItem.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(items: listItems);
      }
    } catch (e) {
      // Failed silently or logged
    }
  }

  Future<void> toggleItem(String id) async {
    final itemIndex = state.items.indexWhere((i) => i.id == id);
    if (itemIndex == -1) return;
    final item = state.items[itemIndex];
    final newChecked = !item.isChecked;

    // Optimistic UI update
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.id == id) return i.copyWith(isChecked: newChecked);
        return i;
      }).toList(),
    );

    try {
      await ListApiService.instance.editItem(
        listId,
        id,
        isChecked: newChecked,
      );
    } catch (e) {
      // Revert on failure
      state = state.copyWith(
        items: state.items.map((i) {
          if (i.id == id) return i.copyWith(isChecked: item.isChecked);
          return i;
        }).toList(),
      );
    }
  }

  Future<void> removeItem(String id) async {
    final originalItems = state.items;
    state = state.copyWith(items: state.items.where((i) => i.id != id).toList());

    try {
      await ListApiService.instance.removeItem(listId, id);
    } catch (e) {
      // Revert on failure
      state = state.copyWith(items: originalItems);
    }
  }

  Future<void> addItem(ShoppingListItem item) async {
    try {
      final data = await ListApiService.instance.addItem(
        listId,
        barcode: item.barcode,
        productName: item.name,
        productImageUrl: item.thumbnailAsset,
        quantity: item.quantity,
        unit: item.unit,
      );
      final newItem = ShoppingListItem.fromJson(data);
      state = state.copyWith(items: [...state.items, newItem]);
    } catch (e) {
      // Failed silently
    }
  }
}

// Family provider — one notifier per list ID
final shoppingListDetailProvider = StateNotifierProvider.family<
    ShoppingListDetailNotifier, ShoppingListDetailState, String>(
  (ref, listId) => ShoppingListDetailNotifier(listId),
);