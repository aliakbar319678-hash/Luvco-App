import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/new_recipe_model.dart';
import '../core/network/recipe_api_service.dart';
import 'recipe_provider.dart';

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
  final Ref _ref;

  NewRecipeNotifier(this._ref) : super(const NewRecipeModel());

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

  Future<void> submitRecipe() async {
    // 1. Upload cover image if needed
    String? coverImageUrl;
    if (state.coverImagePath != null) {
      final file = File(state.coverImagePath!);
      if (file.existsSync()) {
        final fileName = state.coverImagePath!.split('/').last;
        coverImageUrl = await RecipeApiService.instance.uploadRecipeCover(file, fileName);
      } else if (state.coverImagePath!.startsWith('http')) {
        coverImageUrl = state.coverImagePath;
      }
    }

    // 2. Parse ingredients list
    final List<Map<String, dynamic>> parsedIngredients = [];
    final ingLines = state.ingredients.split('\n');
    int ingPos = 1;
    for (final line in ingLines) {
      final trimmed = line.replaceAll(RegExp(r'^[•\-\*\s]+'), '').trim();
      if (trimmed.isNotEmpty) {
        parsedIngredients.add({
          'description': trimmed,
          'position': ingPos++,
        });
      }
    }

    // 3. Parse instructions steps
    final List<Map<String, dynamic>> parsedInstructions = [];
    final instLines = state.instructions.split('\n');
    int instPos = 1;
    for (final line in instLines) {
      final trimmed = line.replaceAll(RegExp(r'^\d+[\.\s\-]+'), '').trim();
      if (trimmed.isNotEmpty) {
        parsedInstructions.add({
          'stepNumber': instPos++,
          'text': trimmed,
        });
      }
    }

    // 4. Map products from addedIngredients
    final List<Map<String, dynamic>> parsedProducts = [];
    int prodPos = 1;
    for (final prod in state.addedIngredients) {
      parsedProducts.add({
        'barcode': (prod.id.startsWith('p') && prod.id.length <= 3) ? null : prod.id,
        'productName': prod.name,
        'productImageUrl': prod.imageUrl ?? '',
        'quantity': 1,
        'position': prodPos++,
      });
    }

    // 5. Create payload
    final payload = {
      'title': state.recipeName.trim(),
      'description': state.description.trim(),
      'coverImageUrl': coverImageUrl,
      'servings': int.tryParse(state.servings ?? '') ?? 2,
      'prepTimeMinutes': int.tryParse(state.timeOfPreparation?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 30,
      'dietTags': state.selectedDietTypes,
      'freeOfTags': state.selectedFreeIngredients,
      'isPublic': true, // default public
      'ingredients': parsedIngredients,
      'instructions': parsedInstructions,
      'products': parsedProducts,
    };

    // 6. Submit to backend
    await RecipeApiService.instance.createRecipe(payload);

    // 7. Refresh lists
    await _ref.read(myRecipesProvider.notifier).loadRecipes();
  }

  void reset() => state = const NewRecipeModel();
}

final newRecipeProvider =
    StateNotifierProvider<NewRecipeNotifier, NewRecipeModel>(
  (ref) => NewRecipeNotifier(ref),
);
