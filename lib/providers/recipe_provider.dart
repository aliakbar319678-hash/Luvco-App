import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';
import '../core/network/recipe_api_service.dart';
import 'user_profile_provider.dart';

// ── Recipe view mode: grid or list ────────────────────────────────
enum RecipeViewMode { grid, list }

final recipeViewModeProvider = StateProvider<RecipeViewMode>(
  (_) => RecipeViewMode.grid,
);

// ── Recipe filter state ───────────────────────────────────────────
class RecipeFilterState {
  final String sortBy; // 'Most Recent', 'Oldest', 'A-Z'
  final List<String> dietFilters;

  const RecipeFilterState({
    this.sortBy = 'Most Recent',
    this.dietFilters = const [],
  });

  RecipeFilterState copyWith({String? sortBy, List<String>? dietFilters}) =>
      RecipeFilterState(
        sortBy: sortBy ?? this.sortBy,
        dietFilters: dietFilters ?? this.dietFilters,
      );
}

class RecipeFilterNotifier extends StateNotifier<RecipeFilterState> {
  RecipeFilterNotifier() : super(const RecipeFilterState());

  void setSortBy(String sort) => state = state.copyWith(sortBy: sort);

  void toggleDietFilter(String filter) {
    final current = List<String>.from(state.dietFilters);
    if (filter == 'See All') {
      state = state.copyWith(dietFilters: []);
      return;
    }
    if (current.contains(filter)) {
      current.remove(filter);
    } else {
      current.add(filter);
    }
    state = state.copyWith(dietFilters: current);
  }
}

final recipeFilterProvider =
    StateNotifierProvider<RecipeFilterNotifier, RecipeFilterState>(
      (_) => RecipeFilterNotifier(),
    );

// ── My Recipes notifier ───────────────────────────────────────────
class MyRecipesNotifier extends StateNotifier<List<RecipeModel>> {
  final Ref _ref;

  MyRecipesNotifier(this._ref) : super([]) {
    loadRecipes();
  }

  Future<void> loadRecipes() async {
    try {
      final list = await RecipeApiService.instance.getRecipes('my-recipes');
      state = list;
    } catch (e) {
      debugPrint("MyRecipesNotifier.loadRecipes Error: $e");
    }
  }

  void addRecipe(RecipeModel recipe) => state = [...state, recipe];

  void editRecipe(RecipeModel updated) {
    state = state.map((r) => r.id == updated.id ? updated : r).toList();
  }

  Future<void> duplicateRecipe(String id) async {
    try {
      final currentUserId = _ref.read(userProfileProvider).value?.id ?? '';
      final detail = await RecipeApiService.instance.getRecipe(id, currentUserId);
      final payload = {
        'title': '${detail.title} (Copy)',
        'description': detail.description,
        'coverImageUrl': detail.imageUrl,
        'servings': detail.servings,
        'prepTimeMinutes': detail.timeMinutes,
        'dietTags': detail.dietTypes,
        'freeOfTags': detail.freeOfIngredients,
        'isPublic': detail.core.isPublic,
        'ingredients': detail.ingredientsList.map((i) => {
          'description': i.description,
          'position': i.position,
        }).toList(),
        'instructions': detail.instructionsList.map((i) => {
          'stepNumber': i.stepNumber,
          'text': i.text,
        }).toList(),
        'products': detail.products.map((p) => {
          'barcode': p.barcode,
          'productName': p.productName,
          'productImageUrl': p.productImageUrl,
          'quantity': p.quantity,
          'unit': p.unit,
          'position': p.position,
        }).toList(),
      };
      
      await RecipeApiService.instance.createRecipe(payload);
      await loadRecipes();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteRecipe(String id) async {
    try {
      await RecipeApiService.instance.deleteRecipe(id);
      state = state.where((r) => r.id != id).toList();
    } catch (e) {
      // Handle error
    }
  }
}

final myRecipesProvider =
    StateNotifierProvider<MyRecipesNotifier, List<RecipeModel>>(
      (ref) => MyRecipesNotifier(ref),
    );

// ── Saved Recipes notifier ────────────────────────────────────────
class SavedRecipesNotifier extends StateNotifier<List<RecipeModel>> {
  SavedRecipesNotifier() : super([]) {
    loadRecipes();
  }

  Future<void> loadRecipes() async {
    try {
      final list = await RecipeApiService.instance.getRecipes('saved');
      state = list;
    } catch (e) {
      debugPrint("SavedRecipesNotifier.loadRecipes Error: $e");
    }
  }

  Future<void> deleteRecipe(String id) async {
    try {
      // Unsave the recipe on the backend
      await RecipeApiService.instance.unsaveRecipe(id);
      state = state.where((r) => r.id != id).toList();
    } catch (e) {
      // Handle error
    }
  }
}

final savedRecipesProvider =
    StateNotifierProvider<SavedRecipesNotifier, List<RecipeModel>>(
      (_) => SavedRecipesNotifier(),
    );
