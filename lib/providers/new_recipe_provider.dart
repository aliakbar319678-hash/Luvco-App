import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/new_recipe_model.dart';

// ── Current step (1, 2, 3) ─────────────────────────────────────────
final newRecipeStepProvider = StateProvider<int>((ref) => 1);

// ── Success dialog visibility ──────────────────────────────────────
final ingredientAddedSuccessProvider = StateProvider<bool>((ref) => false);
final recipeCreatedSuccessProvider = StateProvider<bool>((ref) => false);

// ── Product search query ───────────────────────────────────────────
final productSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Mock product search results ────────────────────────────────────
class MockProduct {
  final String id;
  final String name;
  final String otherData;
  final String? imageUrl;
  final bool isUnsustainable;
  final bool isSafe;

  const MockProduct({
    required this.id,
    required this.name,
    required this.otherData,
    this.imageUrl,
    this.isUnsustainable = false,
    this.isSafe = true,
  });
}

final mockProductSearchResults = [
  const MockProduct(
    id: 'p1',
    name: 'Name of the Product',
    otherData: 'Other data from the product.',
    imageUrl: 'assets/images/product_image.png',
    isUnsustainable: false,
    isSafe: true,
  ),
  const MockProduct(
    id: 'p2',
    name: 'Name of the Product',
    otherData: 'Other data from the product.',
    imageUrl: 'assets/images/product_image.png',
    isUnsustainable: false,
    isSafe: true,
  ),
  const MockProduct(
    id: 'p3',
    name: 'Name of the Product',
    otherData: 'Other data from the product.',
    imageUrl: 'assets/images/product_image.png',
    isUnsustainable: false,
    isSafe: true,
  ),
];

// ── New Recipe State Notifier ──────────────────────────────────────
class NewRecipeNotifier extends StateNotifier<NewRecipeModel> {
  NewRecipeNotifier() : super(const NewRecipeModel());

  void setCoverImage(String path) => state = state.copyWith(coverImagePath: path);
  void setRecipeName(String v) => state = state.copyWith(recipeName: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setTimeOfPreparation(String v) => state = state.copyWith(timeOfPreparation: v);
  void setServings(String v) => state = state.copyWith(servings: v);

  void toggleDietType(String v) {
    final list = List<String>.from(state.selectedDietTypes);
    if (list.contains(v)) {
      list.remove(v);
    } else {
      list.add(v);
    }
    state = state.copyWith(selectedDietTypes: list);
  }

  void toggleFreeIngredient(String v) {
    final list = List<String>.from(state.selectedFreeIngredients);
    if (list.contains(v)) {
      list.remove(v);
    } else {
      list.add(v);
    }
    state = state.copyWith(selectedFreeIngredients: list);
  }

  void setIngredients(String v) => state = state.copyWith(ingredients: v);
  void setInstructions(String v) => state = state.copyWith(instructions: v);

  void addIngredient(AddedIngredient ingredient) {
    final list = List<AddedIngredient>.from(state.addedIngredients);
    list.add(ingredient);
    state = state.copyWith(addedIngredients: list);
  }

  void removeIngredient(String id) {
    final list = state.addedIngredients.where((i) => i.id != id).toList();
    state = state.copyWith(addedIngredients: list);
  }

  void reset() => state = const NewRecipeModel();
}

final newRecipeProvider =
    StateNotifierProvider<NewRecipeNotifier, NewRecipeModel>(
  (_) => NewRecipeNotifier(),
);
