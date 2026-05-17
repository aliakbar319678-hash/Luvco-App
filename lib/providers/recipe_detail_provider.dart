import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_detail_model.dart';

// ── Active tab: 0=Ingredients 1=Instructions 2=Products ───────────
final recipeDetailTabProvider = StateProvider.autoDispose<int>((_) => 0);

// ── More actions popup visibility ─────────────────────────────────
final recipeDetailMoreActionsProvider = StateProvider.autoDispose<bool>(
  (_) => false,
);

// ── Duplicate success dialog ───────────────────────────────────────
final recipeDuplicatedSuccessProvider = StateProvider.autoDispose<bool>(
  (_) => false,
);

// ── Edit recipe tab (0=Details 1=Preparation 2=Products) ──────────
final editRecipeTabProvider = StateProvider.autoDispose<int>((_) => 0);

// ── Recipe Detail State Notifier ──────────────────────────────────
class RecipeDetailNotifier extends StateNotifier<RecipeDetailModel> {
  RecipeDetailNotifier(super.initial);

  void updateDetails({
    String? title,
    String? description,
    int? servings,
    int? timeMinutes,
    List<String>? dietTypes,
    List<String>? freeOfIngredients,
    String? imageUrl,
  }) {
    state = state.copyWith(
      title: title,
      description: description,
      servings: servings,
      timeMinutes: timeMinutes,
      dietTypes: dietTypes,
      freeOfIngredients: freeOfIngredients,
      imageUrl: imageUrl,
    );
  }

  void updatePreparation({String? ingredients, String? instructions}) {
    state = state.copyWith(
      ingredients: ingredients,
      instructions: instructions,
    );
  }

  void addProduct(RecipeProduct product) {
    state = state.copyWith(products: [...state.products, product]);
  }

  void removeProduct(String id) {
    state = state.copyWith(
      products: state.products.where((p) => p.id != id).toList(),
    );
  }
}

// Family provider so each recipe gets its own notifier
final recipeDetailProvider = StateNotifierProvider.autoDispose
    .family<RecipeDetailNotifier, RecipeDetailModel, RecipeDetailModel>(
      (_, initial) => RecipeDetailNotifier(initial),
    );

// ── Demo recipe for testing ────────────────────────────────────────
const demoRecipeDetail = RecipeDetailModel(
  id: 'demo_1',
  title: 'Recipe Title',
  description: 'Short description of the recipe.',
  imageUrl: 'assets/images/rice_image.png',
  servings: 2,
  timeMinutes: 30,
  dietTypes: ['Label', 'Label', 'Label', 'Label'],
  freeOfIngredients: ['Label', 'Label', 'Label', 'Label'],
  ingredients: '''• 4 cups (500g) all-purpose flour
- 1 ½ teaspoons salt
- 1 tablespoon sugar
- 2 ¼ teaspoons (1 packet) instant yeast
- 1 ¼ cups (300ml) warm water
- 1 tablespoon vegetable oil''',
  instructions: '''1. Make the Dough:
In a large bowl, mix the flour, salt, sugar, and instant yeast.
Gradually add warm water and oil, mixing until a rough dough forms.
Knead the dough on a floured surface for about 8–10 minutes until smooth and elastic.

2. Proof the Dough:
Place the dough in a lightly oiled bowl, cover with a damp cloth, and let rise in a warm place for 1–1.5 hours, or until it doubles in size.

3. Shape the Bagels:
Punch down the dough and divide it into 8 equal pieces.
Roll each piece into a ball, then poke a hole in the center with your finger. Stretch the hole to about 1–2 inches wide (it will shrink slightly during baking).
Place the shaped bagels on a baking sheet.''',
  products: [
    RecipeProduct(
      id: 'prod_1',
      name: 'Name of the Product',
      otherData: 'Other data from the product.',
      sustainabilityLevel: 'Unsustainable',
      safetyLevel: 'Avoid',
      imageAsset: 'assets/images/product_image.png',
    ),
    RecipeProduct(
      id: 'prod_2',
      name: 'Name of the Product',
      otherData: 'Other data from the product.',
      sustainabilityLevel: 'Moderate Impact',
      safetyLevel: 'Safe',
      imageAsset: 'assets/images/product_image.png',
    ),
    RecipeProduct(
      id: 'prod_3',
      name: 'Name of the Product',
      otherData: 'Other data from the product.',
      sustainabilityLevel: 'Eco-Friendly',
      safetyLevel: 'Safe',
      imageAsset: 'assets/images/product_image.png',
    ),
  ],
  isOwner: true,
);
