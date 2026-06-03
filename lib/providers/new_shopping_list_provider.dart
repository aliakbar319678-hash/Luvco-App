import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';

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
  final bool isCreating; // loading state while creati g list
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
// Demo product catalogue — replace with real API call
// ─────────────────────────────────────────────────────────────────
const _demoCatalogue = [
  ProductModel(
    id: 'p1',
    name: 'Food Item 01',
    description: 'Other data from the product.',
    imageAsset: 'assets/images/product_image.png',
    thumbnailAsset: 'assets/images/nutila.png',
    imageSvgAsset: 'assets/images/nutila.svg',
    isSustainable: false,
    labels: ['Label', 'Label', 'Label', 'Label'],
    allergens: ['Label', 'Label', 'Label', 'Label'],
    ingredients: ['Ingredient Name'],
  ),
  ProductModel(
    id: 'p2',
    name: 'Food Item 02',
    description: 'Other data from the product.',
    imageAsset: 'assets/images/product_image.png',
    thumbnailAsset: 'assets/images/nutila.png',
    imageSvgAsset: 'assets/images/nutila.svg',
    isSustainable: true,
    labels: ['Label', 'Label', 'Label', 'Label'],
    allergens: ['Label', 'Label', 'Label', 'Label'],
    ingredients: ['Ingredient Name'],
  ),
  ProductModel(
    id: 'p3',
    name: 'Food Item 03',
    description: 'Other data from the product.',
    imageAsset: 'assets/images/product_image.png',
    thumbnailAsset: 'assets/images/nutila.png',
    imageSvgAsset: 'assets/images/nutila.svg',
    isSustainable: false,
    labels: ['Label', 'Label', 'Label', 'Label'],
    allergens: ['Label', 'Label', 'Label', 'Label'],
    ingredients: ['Ingredient Name'],
  ),
];

// ─────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────
class NewShoppingListNotifier extends StateNotifier<NewShoppingListState> {
  NewShoppingListNotifier() : super(const NewShoppingListState());

  // ── Field updates ─────────────────────────────────────────────
  void setListName(String value) => state = state.copyWith(listName: value);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  // ── Search ────────────────────────────────────────────────────
  void onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        searchResults: [],
        isSearching: false,
      );
      return;
    }
    // Filter demo catalogue — replace with API call
    final results = _demoCatalogue
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    // If nothing matches, still show all demo items (like real search UX)
    state = state.copyWith(
      searchQuery: query,
      searchResults: results.isEmpty ? _demoCatalogue : results,
      isSearching: true,
    );
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
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(isCreating: false, listCreated: true);
  }

  void dismissSuccess() => state = state.copyWith(listCreated: false);

  // ── Full reset (called on pop/dispose) ────────────────────────
  void reset() => state = const NewShoppingListState();
}

final newShoppingListProvider =
    StateNotifierProvider.autoDispose<
      NewShoppingListNotifier,
      NewShoppingListState
    >((_) => NewShoppingListNotifier());
