import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── A single product item inside a shopping list ─────────────────
class ShoppingListItem {
  final String id;
  final String name;
  final String description;
  final String? thumbnailAsset;
  final bool isChecked;

  const ShoppingListItem({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnailAsset,
    this.isChecked = false,
  });

  ShoppingListItem copyWith({
    String? id,
    String? name,
    String? description,
    String? thumbnailAsset,
    bool? isChecked,
  }) =>
      ShoppingListItem(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        thumbnailAsset: thumbnailAsset ?? this.thumbnailAsset,
        isChecked: isChecked ?? this.isChecked,
      );
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
  ShoppingListDetailNotifier(String listId)
      : super(ShoppingListDetailState(
          listId: listId,
          items: _demoItems,
        ));

  static final _demoItems = [
    const ShoppingListItem(
      id: '1',
      name: 'Name of the Product',
      description: 'Other data related from the product.',
      thumbnailAsset: 'assets/images/cruesli_image.png',
    ),
    const ShoppingListItem(
      id: '2',
      name: 'Name of the Product',
      description: 'Other data related from the product.',
      thumbnailAsset: 'assets/images/cruesli_image.png',
    ),
    const ShoppingListItem(
      id: '3',
      name: 'Name of the Product',
      description: 'Other data related from the product.',
      thumbnailAsset: 'assets/images/cruesli_image.png',
    ),
    const ShoppingListItem(
      id: '4',
      name: 'Name of the Product',
      description: 'Other data related from the product.',
      thumbnailAsset: 'assets/images/cruesli_image.png',
    ),
  ];

  void toggleItem(String id) {
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id == id) return item.copyWith(isChecked: !item.isChecked);
        return item;
      }).toList(),
    );
  }

  void removeItem(String id) {
    state =
        state.copyWith(items: state.items.where((i) => i.id != id).toList());
  }

  void addItem(ShoppingListItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }
}

// Family provider — one notifier per list ID
final shoppingListDetailProvider = StateNotifierProvider.family<
    ShoppingListDetailNotifier, ShoppingListDetailState, String>(
  (ref, listId) => ShoppingListDetailNotifier(listId),
);