import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';

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
  final List<String> shoppingLists;
  final List<String> selectedLists;

  // For "Add to Recipe" dialog
  final List<String> recipes;
  final List<String> selectedRecipes;

  const ProductDetailState({
    required this.product,
    this.isFavorite = false,
    this.popup = ProductDetailPopup.none,
    this.shoppingLists = const [
      'Shopping List 01',
      'Shopping List 02',
      'Shopping List 03',
      'Shopping List 04',
    ],
    this.selectedLists = const [],
    this.recipes = const ['Recipe 01', 'Recipe 02', 'Recipe 03'],
    this.selectedRecipes = const [],
  });

  ProductDetailState copyWith({
    ProductModel? product,
    bool? isFavorite,
    ProductDetailPopup? popup,
    List<String>? shoppingLists,
    List<String>? selectedLists,
    List<String>? recipes,
    List<String>? selectedRecipes,
  }) => ProductDetailState(
    product: product ?? this.product,
    isFavorite: isFavorite ?? this.isFavorite,
    popup: popup ?? this.popup,
    shoppingLists: shoppingLists ?? this.shoppingLists,
    selectedLists: selectedLists ?? this.selectedLists,
    recipes: recipes ?? this.recipes,
    selectedRecipes: selectedRecipes ?? this.selectedRecipes,
  );
}

// ─────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────
class ProductDetailNotifier extends StateNotifier<ProductDetailState> {
  ProductDetailNotifier(ProductModel product)
    : super(ProductDetailState(product: product));

  void toggleFavorite() =>
      state = state.copyWith(isFavorite: !state.isFavorite);

  void showMoreActions() =>
      state = state.copyWith(popup: ProductDetailPopup.moreActions);

  void showAddToList() =>
      state = state.copyWith(popup: ProductDetailPopup.addToList);

  void showAddToRecipe() =>
      state = state.copyWith(popup: ProductDetailPopup.addToRecipe);

  void closePopup() => state = state.copyWith(popup: ProductDetailPopup.none);

  void toggleList(String list) {
    final updated = List<String>.from(state.selectedLists);
    updated.contains(list) ? updated.remove(list) : updated.add(list);
    state = state.copyWith(selectedLists: updated);
  }

  void toggleRecipe(String recipe) {
    final updated = List<String>.from(state.selectedRecipes);
    updated.contains(recipe) ? updated.remove(recipe) : updated.add(recipe);
    state = state.copyWith(selectedRecipes: updated);
  }

  void saveOnList() =>
      state = state.copyWith(popup: ProductDetailPopup.none, selectedLists: []);

  void saveOnRecipe() => state = state.copyWith(
    popup: ProductDetailPopup.none,
    selectedRecipes: [],
  );
}

// Family provider — one notifier per product
final productDetailProvider = StateNotifierProvider.autoDispose
    .family<ProductDetailNotifier, ProductDetailState, ProductModel>(
      (_, product) => ProductDetailNotifier(product),
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
