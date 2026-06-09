import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../core/network/list_api_service.dart';
import '../core/network/product_api_service.dart';
import 'shopping_list_provider.dart';

// ─────────────────────────────────────────────────────────────────
// State class — holds everything for the New Shopping List screen
// ─────────────────────────────────────────────────────────────────
class NewShoppingListState {
  final String listName;
  final String description;
  final String searchQuery;
  final List<ProductModel> searchResults;
  final List<ProductModel> addedProducts;
  final bool isSearching; // search bar is active / has text
  final bool isCreating; // loading state while creating list
  final bool listCreated; // success overlay visible

  const NewShoppingListState({
    this.listName = '',
    this.description = '',
    this.searchQuery = '',
    this.searchResults = const [],
    this.addedProducts = const [],
    this.isSearching = false,
    this.isCreating = false,
    this.listCreated = false,
  });

  bool get canCreate => listName.trim().isNotEmpty;

  NewShoppingListState copyWith({
    String? listName,
    String? description,
    String? searchQuery,
    List<ProductModel>? searchResults,
    List<ProductModel>? addedProducts,
    bool? isSearching,
    bool? isCreating,
    bool? listCreated,
  }) => NewShoppingListState(
    listName: listName ?? this.listName,
    description: description ?? this.description,
    searchQuery: searchQuery ?? this.searchQuery,
    searchResults: searchResults ?? this.searchResults,
    addedProducts: addedProducts ?? this.addedProducts,
    isSearching: isSearching ?? this.isSearching,
    isCreating: isCreating ?? this.isCreating,
    listCreated: listCreated ?? this.listCreated,
  );
}

// ─────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────
class NewShoppingListNotifier extends StateNotifier<NewShoppingListState> {
  final Ref _ref;

  NewShoppingListNotifier(this._ref) : super(const NewShoppingListState());

  // ── Field updates ─────────────────────────────────────────────
  void setListName(String value) => state = state.copyWith(listName: value);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  // ── Search ────────────────────────────────────────────────────
  Future<void> onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        searchResults: [],
        isSearching: false,
      );
      return;
    }
    
    state = state.copyWith(searchQuery: query, isSearching: true);
    
    try {
      final results = await ProductApiService.instance.searchProducts(query);
      state = state.copyWith(searchResults: results);
    } catch (e) {
      // Fail silently or keep current results
    }
  }

  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      searchResults: [],
      isSearching: false,
    );
  }

  // ── Add product to list ───────────────────────────────────────
  void addProduct(ProductModel product) {
    final alreadyAdded = state.addedProducts.any((p) => p.id == product.id);
    if (alreadyAdded) return;
    state = state.copyWith(addedProducts: [...state.addedProducts, product]);
  }

  // ── Remove product from list ──────────────────────────────────
  void removeProduct(String productId) {
    state = state.copyWith(
      addedProducts: state.addedProducts
          .where((p) => p.id != productId)
          .toList(),
    );
  }

  // ── Create shopping list ──────────────────────────────────────
  Future<void> createList() async {
    if (!state.canCreate) return;
    state = state.copyWith(isCreating: true);
    
    try {
      // 1. Create shopping list on the backend
      final createdList = await ListApiService.instance.createList(state.listName);
      
      // 2. Add each product sequentially
      for (final product in state.addedProducts) {
        await ListApiService.instance.addItem(
          createdList.id,
          barcode: product.id,
          productName: product.name,
          productImageUrl: product.imageAsset ?? product.thumbnailAsset,
          quantity: 1,
        );
      }
      
      // 3. Refresh list on main lists screen
      await _ref.read(shoppingListProvider.notifier).loadLists();
      
      state = state.copyWith(isCreating: false, listCreated: true);
    } catch (e) {
      state = state.copyWith(isCreating: false);
      // Fail silently or handle error appropriately
    }
  }

  void dismissSuccess() => state = state.copyWith(listCreated: false);

  // ── Full reset (called on pop/dispose) ────────────────────────
  void reset() => state = const NewShoppingListState();
}

final newShoppingListProvider =
    StateNotifierProvider.autoDispose<
      NewShoppingListNotifier,
      NewShoppingListState
    >((ref) => NewShoppingListNotifier(ref));
