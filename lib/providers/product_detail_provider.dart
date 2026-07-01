import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/shopping_list_model.dart';
import '../models/recipe_model.dart';
import '../core/network/list_api_service.dart';
import '../core/network/recipe_api_service.dart';
import '../core/network/product_api_service.dart';
import 'favorites_provider.dart';

// ─────────────────────────────────────────────────
// More Actions popup state
// ─────────────────────────────────────────────────
enum ProductDetailPopup { none, moreActions, addToList, addToRecipe }

// ─────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────
class ProductDetailState {
  final ProductModel product;
  final bool isFavorite;
  final ProductDetailPopup popup;

  // For "Add to Shopping List" dialog
  final List<ShoppingListModel> shoppingLists;
  final List<String> selectedLists; // list IDs

  // For "Add to Recipe" dialog
  final List<RecipeModel> recipes;
  final List<String> selectedRecipes; // recipe IDs

  // Save status
  final bool isSaving;
  final String? saveMessage;

  const ProductDetailState({
    required this.product,
    this.isFavorite = false,
    this.popup = ProductDetailPopup.none,
    this.shoppingLists = const [],
    this.selectedLists = const [],
    this.recipes = const [],
    this.selectedRecipes = const [],
    this.isSaving = false,
    this.saveMessage,
  });

  ProductDetailState copyWith({
    ProductModel? product,
    bool? isFavorite,
    ProductDetailPopup? popup,
    List<ShoppingListModel>? shoppingLists,
    List<String>? selectedLists,
    List<RecipeModel>? recipes,
    List<String>? selectedRecipes,
    bool? isSaving,
    String? saveMessage,
  }) => ProductDetailState(
    product: product ?? this.product,
    isFavorite: isFavorite ?? this.isFavorite,
    popup: popup ?? this.popup,
    shoppingLists: shoppingLists ?? this.shoppingLists,
    selectedLists: selectedLists ?? this.selectedLists,
    recipes: recipes ?? this.recipes,
    selectedRecipes: selectedRecipes ?? this.selectedRecipes,
    isSaving: isSaving ?? this.isSaving,
    saveMessage: saveMessage,
  );
}

// ─────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────
class ProductDetailNotifier extends StateNotifier<ProductDetailState> {
  final Ref _ref;

  ProductDetailNotifier(ProductModel product, this._ref)
    : super(ProductDetailState(
        product: product,
        isFavorite: _ref.read(favoritesProvider).items.any((i) => i.barcode == product.id),
      )) {
    _loadData();
  }

  Future<void> _loadData() async {
    // Load lists, recipes, and product details in parallel
    await Future.wait([
      _loadShoppingLists(),
      _loadRecipes(),
      _lookupProductDetails(),
    ]);
  }

  Future<void> _lookupProductDetails() async {
    try {
      final fullProduct = await ProductApiService.instance.lookupProduct(state.product.id);
      if (mounted) {
        state = state.copyWith(product: fullProduct);
      }
    } catch (_) {
      // Keep existing product if fetch fails
    }
  }

  Future<void> _loadShoppingLists() async {
    try {
      final lists = await ListApiService.instance.getLists();
      if (mounted) state = state.copyWith(shoppingLists: lists);
    } catch (_) {}
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await RecipeApiService.instance.getRecipes('my-recipes');
      if (mounted) state = state.copyWith(recipes: recipes);
    } catch (_) {}
  }

  Future<void> toggleFavorite() async {
    final barcode = state.product.id;
    final isFav = state.isFavorite;

    // Optimistic UI state toggle
    state = state.copyWith(isFavorite: !isFav);

    try {
      if (isFav) {
        await _ref.read(favoritesProvider.notifier).removeItem(barcode);
      } else {
        await _ref.read(favoritesProvider.notifier).addFavorite(
          barcode: barcode,
          productName: state.product.name,
          productImageUrl: state.product.thumbnailAsset,
        );
      }
    } catch (e) {
      // Rollback on failure
      if (mounted) {
        state = state.copyWith(isFavorite: isFav);
      }
    }
  }

  void showMoreActions() =>
      state = state.copyWith(popup: ProductDetailPopup.moreActions);

  void showAddToList() =>
      state = state.copyWith(popup: ProductDetailPopup.addToList, selectedLists: []);

  void showAddToRecipe() =>
      state = state.copyWith(popup: ProductDetailPopup.addToRecipe, selectedRecipes: []);

  void closePopup() => state = state.copyWith(popup: ProductDetailPopup.none);

  void toggleList(String listId) {
    final updated = List<String>.from(state.selectedLists);
    updated.contains(listId) ? updated.remove(listId) : updated.add(listId);
    state = state.copyWith(selectedLists: updated);
  }

  void toggleRecipe(String recipeId) {
    final updated = List<String>.from(state.selectedRecipes);
    updated.contains(recipeId) ? updated.remove(recipeId) : updated.add(recipeId);
    state = state.copyWith(selectedRecipes: updated);
  }

  Future<String?> saveOnList() async {
    if (state.selectedLists.isEmpty) return 'Please select at least one list';
    state = state.copyWith(isSaving: true);
    int successCount = 0;
    String? lastError;
    for (final listId in state.selectedLists) {
      try {
        await ListApiService.instance.addItem(
          listId,
          barcode: state.product.id,
          productName: state.product.name,
          productImageUrl: state.product.thumbnailAsset ?? '',
          quantity: 1,
        );
        successCount++;
      } catch (e) {
        lastError = e.toString();
      }
    }
    if (!mounted) return null;
    state = state.copyWith(
      popup: ProductDetailPopup.none,
      selectedLists: [],
      isSaving: false,
    );
    if (successCount > 0) {
      return successCount == 1
          ? 'Product added to shopping list!'
          : 'Product added to $successCount lists!';
    }
    if (lastError != null) {
      final errorLower = lastError.toLowerCase();
      if (errorLower.contains('already present') ||
          errorLower.contains('already exist') ||
          errorLower.contains('conflict') ||
          errorLower.contains('duplicate')) {
        return 'Product is already exist';
      }
      return lastError;
    }
    return 'Failed to add product. Please try again.';
  }

  Future<String?> saveOnRecipe() async {
    if (state.selectedRecipes.isEmpty) return 'Please select at least one recipe';
    state = state.copyWith(isSaving: true);
    int successCount = 0;
    for (final recipeId in state.selectedRecipes) {
      try {
        await RecipeApiService.instance.addLinkedProduct(recipeId, {
          'barcode': state.product.id,
          'productName': state.product.name,
          'productImageUrl': state.product.thumbnailAsset ?? '',
          'quantity': 1,
          'position': 1,
        });
        successCount++;
      } catch (_) {}
    }
    if (!mounted) return null;
    state = state.copyWith(
      popup: ProductDetailPopup.none,
      selectedRecipes: [],
      isSaving: false,
    );
    if (successCount > 0) {
      return successCount == 1
          ? 'Product added to recipe!'
          : 'Product added to $successCount recipes!';
    }
    return 'Failed to add product. Please try again.';
  }
}

// Family provider — one notifier per product
final productDetailProvider = StateNotifierProvider.autoDispose
    .family<ProductDetailNotifier, ProductDetailState, ProductModel>(
      (ref, product) => ProductDetailNotifier(product, ref),
    );

// ─────────────────────────────────────────────────
// Demo product for testing
// ─────────────────────────────────────────────────
const demoProduct = ProductModel(
  id: 'demo_prod_1',
  name: 'Name of the Product',
  description: 'Other data from the product.',
  imageAsset: 'assets/images/nutila.png',
  thumbnailAsset: 'assets/images/nutila.png',
  isSustainable: false,
  labels: ['Label', 'Label', 'Label', 'Label'],
  allergens: ['Label', 'Label', 'Label', 'Label'],
  ingredients: [
    'Ingredient Name',
    'Ingredient Name',
    'Ingredient Name',
    'Ingredient Name',
    'Ingredient Name',
    'Ingredient Name',
  ],
);
