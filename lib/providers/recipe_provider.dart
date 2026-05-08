import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';

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
  MyRecipesNotifier() : super(_demoMyRecipes);

  static final _demoMyRecipes = [
    RecipeModel(
      id: '1',
      title: 'Name of the Recipe',
      description: 'Other data from the recipe.',
      imageUrl: 'assets/images/recipe..png',
      dietTags: ['Gluten Free', 'Label 02', 'Label 03'],
    ),
    RecipeModel(
      id: '2',
      title: 'Name of the Recipe',
      description: 'Other data from the recipe.',
      imageUrl: 'assets/images/recipe..png',
      dietTags: ['Gluten Free', 'Label 02'],
    ),
  ];

  void addRecipe(RecipeModel recipe) => state = [...state, recipe];

  void editRecipe(RecipeModel updated) {
    state = state.map((r) => r.id == updated.id ? updated : r).toList();
  }

  void duplicateRecipe(String id) {
    final original = state.firstWhere((r) => r.id == id);
    final copy = original.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${original.title} (Copy)',
    );
    state = [...state, copy];
  }

  void deleteRecipe(String id) =>
      state = state.where((r) => r.id != id).toList();
}

final myRecipesProvider =
    StateNotifierProvider<MyRecipesNotifier, List<RecipeModel>>(
      (_) => MyRecipesNotifier(),
    );

// ── Saved Recipes notifier ────────────────────────────────────────
class SavedRecipesNotifier extends StateNotifier<List<RecipeModel>> {
  SavedRecipesNotifier() : super(_demoSavedRecipes);

  static final _demoSavedRecipes = [
    RecipeModel(
      id: 's1',
      title: 'Name of the Recipe',
      description: 'Other data from the recipe.',
      imageUrl: 'assets/images/recipe..png',
      dietTags: ['Gluten Free', 'Label 02'],
      isSaved: true,
    ),
    RecipeModel(
      id: 's2',
      title: 'Name of the Recipe',
      description: 'Other data from the recipe.',
      imageUrl: 'assets/images/recipe..png',
      dietTags: ['Gluten Free'],
      isSaved: true,
    ),
  ];

  void deleteRecipe(String id) =>
      state = state.where((r) => r.id != id).toList();
}

final savedRecipesProvider =
    StateNotifierProvider<SavedRecipesNotifier, List<RecipeModel>>(
      (_) => SavedRecipesNotifier(),
    );
