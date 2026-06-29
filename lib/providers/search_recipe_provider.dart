import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';
import '../core/network/recipe_api_service.dart';

// ─────────────────────────────────────────────────
// Filter State
// ─────────────────────────────────────────────────
class SearchRecipeFilter {
  final String sortBy;
  final List<String> filter2Tags;
  final List<String> filter3Tags;

  const SearchRecipeFilter({
    this.sortBy = 'Most Recent',
    this.filter2Tags = const [],
    this.filter3Tags = const [],
  });

  SearchRecipeFilter copyWith({
    String? sortBy,
    List<String>? filter2Tags,
    List<String>? filter3Tags,
  }) => SearchRecipeFilter(
    sortBy: sortBy ?? this.sortBy,
    filter2Tags: filter2Tags ?? this.filter2Tags,
    filter3Tags: filter3Tags ?? this.filter3Tags,
  );
}

// ─────────────────────────────────────────────────
// Search Recipe State
// ─────────────────────────────────────────────────
class SearchRecipeState {
  final String query;
  final bool isSearching;
  final bool isFetching; // true while initial public recipes are loading
  final List<RecipeModel> results;
  final SearchRecipeFilter filter;
  final RecipeModel? selectedRecipe; // for quick-view card modal
  final bool showMoreActions; // for "..." popup
  final String? moreActionsRecipeId;

  const SearchRecipeState({
    this.query = '',
    this.isSearching = false,
    this.isFetching = true,
    this.results = const [],
    this.filter = const SearchRecipeFilter(),
    this.selectedRecipe,
    this.showMoreActions = false,
    this.moreActionsRecipeId,
  });

  SearchRecipeState copyWith({
    String? query,
    bool? isSearching,
    bool? isFetching,
    List<RecipeModel>? results,
    SearchRecipeFilter? filter,
    RecipeModel? selectedRecipe,
    bool clearSelected = false,
    bool? showMoreActions,
    String? moreActionsRecipeId,
    bool clearMoreActions = false,
  }) => SearchRecipeState(
    query: query ?? this.query,
    isSearching: isSearching ?? this.isSearching,
    isFetching: isFetching ?? this.isFetching,
    results: results ?? this.results,
    filter: filter ?? this.filter,
    selectedRecipe: clearSelected
        ? null
        : selectedRecipe ?? this.selectedRecipe,
    showMoreActions: showMoreActions ?? this.showMoreActions,
    moreActionsRecipeId: clearMoreActions
        ? null
        : moreActionsRecipeId ?? this.moreActionsRecipeId,
  );
}

// ─────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────
class SearchRecipeNotifier extends StateNotifier<SearchRecipeState> {
  SearchRecipeNotifier() : super(const SearchRecipeState()) {
    fetchRecipes();
  }

  List<RecipeModel> _allRecipes = [];

  Future<void> fetchRecipes() async {
    try {
      final recipes = await RecipeApiService.instance.getRecipes('public');
      _allRecipes = recipes;
      if (state.query.isNotEmpty) {
        _applySearchAndFilters(state.query, state.filter);
      } else {
        state = state.copyWith(isFetching: false);
      }
    } catch (e) {
      state = state.copyWith(isFetching: false);
    }
  }

  void onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        query: '',
        isSearching: false,
        results: [],
        clearSelected: true,
      );
      return;
    }
    _applySearchAndFilters(query, state.filter);
  }

  void _applySearchAndFilters(String query, SearchRecipeFilter filter) {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        query: query,
        filter: filter,
        results: [],
      );
      return;
    }

    // 1. Text filter (on title or diet tags)
    final filtered = _allRecipes.where((r) {
      final matchesQuery = r.title.toLowerCase().contains(query.toLowerCase()) ||
          r.dietTags.any((t) => t.toLowerCase().contains(query.toLowerCase()));
      if (!matchesQuery) return false;

      // 2. Filter 2 (Diet tags)
      if (filter.filter2Tags.isNotEmpty) {
        final matchesDiet = r.dietTags.any((t) => filter.filter2Tags.contains(t));
        if (!matchesDiet) return false;
      }

      // 3. Filter 3 (Free of tags)
      if (filter.filter3Tags.isNotEmpty) {
        final matchesFreeOf = r.freeOfIngredients.any((t) => filter.filter3Tags.contains(t));
        if (!matchesFreeOf) return false;
      }

      return true;
    }).toList();

    // 4. Sort
    if (filter.sortBy == 'Most Recent') {
      filtered.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    } else if (filter.sortBy == 'Popularity') {
      filtered.sort((a, b) => b.saveCount.compareTo(a.saveCount));
    } else if (filter.sortBy == 'Highest Rated') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }

    state = state.copyWith(
      query: query,
      isSearching: true,
      isFetching: false,
      filter: filter,
      results: filtered,
    );
  }

  void clearSearch() {
    state = const SearchRecipeState(isFetching: false);
  }

  void openQuickView(RecipeModel recipe) {
    state = state.copyWith(selectedRecipe: recipe);
  }

  void closeQuickView() {
    state = state.copyWith(clearSelected: true);
  }

  void showMoreActionsFor(String recipeId) {
    state = state.copyWith(
      showMoreActions: true,
      moreActionsRecipeId: recipeId,
    );
  }

  void hideMoreActions() {
    state = state.copyWith(showMoreActions: false, clearMoreActions: true);
  }

  void toggleSave(String recipeId) async {
    final index = _allRecipes.indexWhere((r) => r.id == recipeId);
    if (index == -1) return;

    final recipe = _allRecipes[index];
    final wasSaved = recipe.isSaved;
    final newSaved = !wasSaved;

    // Optimistic update
    _allRecipes[index] = recipe.copyWith(isSaved: newSaved);

    final updatedResults = state.results.map((r) {
      if (r.id == recipeId) return r.copyWith(isSaved: newSaved);
      return r;
    }).toList();

    RecipeModel? updatedSelected = state.selectedRecipe;
    if (updatedSelected != null && updatedSelected.id == recipeId) {
      updatedSelected = updatedSelected.copyWith(isSaved: newSaved);
    }

    state = state.copyWith(
      results: updatedResults,
      selectedRecipe: updatedSelected,
    );

    try {
      if (wasSaved) {
        await RecipeApiService.instance.unsaveRecipe(recipeId);
      } else {
        await RecipeApiService.instance.saveRecipe(recipeId);
      }
    } catch (e) {
      // Revert on failure
      _allRecipes[index] = recipe.copyWith(isSaved: wasSaved);

      final revertedResults = state.results.map((r) {
        if (r.id == recipeId) return r.copyWith(isSaved: wasSaved);
        return r;
      }).toList();

      RecipeModel? revertedSelected = state.selectedRecipe;
      if (revertedSelected != null && revertedSelected.id == recipeId) {
        revertedSelected = revertedSelected.copyWith(isSaved: wasSaved);
      }

      state = state.copyWith(
        results: revertedResults,
        selectedRecipe: revertedSelected,
      );
    }
  }

  void updateFilter(SearchRecipeFilter filter) {
    _applySearchAndFilters(state.query, filter);
  }

  void reset() => state = const SearchRecipeState();
}

final searchRecipeProvider =
    StateNotifierProvider.autoDispose<SearchRecipeNotifier, SearchRecipeState>(
      (_) => SearchRecipeNotifier(),
    );

// Filter sheet open/close
final searchRecipeFilterSheetProvider = StateProvider.autoDispose<bool>(
  (_) => false,
);
