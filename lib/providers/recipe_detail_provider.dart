import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_detail_model.dart';
import '../models/recipe_model.dart';
import '../core/network/recipe_api_service.dart';
import 'user_profile_provider.dart';
import 'recipe_provider.dart';

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
  final Ref _ref;

  RecipeDetailNotifier(this._ref, RecipeDetailModel initial) : super(initial) {
    fetchDetails();
  }

  String get _currentUserId => _ref.read(userProfileProvider).value?.id ?? '';

  Future<void> fetchDetails() async {
    try {
      final loaded = await RecipeApiService.instance.getRecipe(state.id, _currentUserId);
      if (mounted) {
        state = loaded;
      }
    } catch (e) {
      // Fallback: keep initial/current state
    }
  }

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
      core: state.core.copyWith(
        title: title ?? state.title,
        description: description ?? state.description,
        servings: servings ?? state.servings,
        timeOfPreparation: timeMinutes ?? state.timeMinutes,
        dietTags: dietTypes ?? state.dietTypes,
        freeOfIngredients: freeOfIngredients ?? state.freeOfIngredients,
        imageUrl: imageUrl ?? state.imageUrl,
      ),
    );
  }

  Future<void> toggleBookmark() async {
    final detail = state;
    final currentlySaved = detail.isSaved;

    state = detail.copyWith(
      core: detail.core.copyWith(isSaved: !currentlySaved),
    );

    try {
      if (currentlySaved) {
        await RecipeApiService.instance.unsaveRecipe(detail.id);
      } else {
        await RecipeApiService.instance.saveRecipe(detail.id);
      }
      if (mounted) {
        _ref.read(savedRecipesProvider.notifier).loadRecipes();
      }
    } catch (e) {
      // Revert on failure
      if (mounted) {
        state = detail.copyWith(
          core: detail.core.copyWith(isSaved: currentlySaved),
        );
      }
    }
  }

  Future<void> addIngredient(String description) async {
    final nextPosition = state.ingredientsList.length + 1;
    try {
      final newIng = await RecipeApiService.instance.addIngredient(state.id, description, nextPosition);
      if (mounted) {
        state = state.copyWith(
          ingredientsList: [...state.ingredientsList, newIng],
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> removeIngredient(String ingredientId) async {
    try {
      await RecipeApiService.instance.removeIngredient(state.id, ingredientId);
      if (mounted) {
        state = state.copyWith(
          ingredientsList: state.ingredientsList.where((i) => i.id != ingredientId).toList(),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addInstructionStep(String text) async {
    final nextStepNumber = state.instructionsList.length + 1;
    try {
      final newStep = await RecipeApiService.instance.addInstructionStep(state.id, text, nextStepNumber);
      if (mounted) {
        state = state.copyWith(
          instructionsList: [...state.instructionsList, newStep],
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> removeInstructionStep(String stepId) async {
    try {
      await RecipeApiService.instance.removeInstructionStep(state.id, stepId);
      if (mounted) {
        state = state.copyWith(
          instructionsList: state.instructionsList.where((i) => i.id != stepId).toList(),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    final nextPosition = state.products.length + 1;
    final fullData = {
      ...productData,
      'position': nextPosition,
    };
    try {
      final newProd = await RecipeApiService.instance.addLinkedProduct(state.id, fullData);
      if (mounted) {
        state = state.copyWith(
          products: [...state.products, newProd],
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> removeProduct(String productId) async {
    try {
      await RecipeApiService.instance.removeLinkedProduct(state.id, productId);
      if (mounted) {
        state = state.copyWith(
          products: state.products.where((p) => p.id != productId).toList(),
        );
      }
    } catch (e) {
      // Handle error
    }
  }
}

// Family provider so each recipe gets its own notifier
final recipeDetailProvider = StateNotifierProvider.autoDispose
    .family<RecipeDetailNotifier, RecipeDetailModel, RecipeDetailModel>(
      (ref, initial) => RecipeDetailNotifier(ref, initial),
    );

// ── Demo recipe for testing ────────────────────────────────────────
const demoRecipeDetail = RecipeDetailModel(
  core: RecipeModel(
    id: 'demo_1',
    title: 'Recipe Title',
    description: 'Short description of the recipe.',
    imageUrl: 'assets/images/rice_image.png',
    servings: 2,
    timeOfPreparation: 30,
    dietTags: ['Label', 'Label', 'Label', 'Label'],
    freeOfIngredients: ['Label', 'Label', 'Label', 'Label'],
    isSaved: false,
  ),
  isOwner: true,
);
