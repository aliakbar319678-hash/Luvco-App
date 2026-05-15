import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';

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
  final List<RecipeModel> results;
  final SearchRecipeFilter filter;
  final RecipeModel? selectedRecipe; // for quick-view card modal
  final bool showMoreActions; // for "..." popup
  final String? moreActionsRecipeId;

  const SearchRecipeState({
    this.query = '',
    this.isSearching = false,
    this.results = const [],
    this.filter = const SearchRecipeFilter(),
    this.selectedRecipe,
    this.showMoreActions = false,
    this.moreActionsRecipeId,
  });

  SearchRecipeState copyWith({
    String? query,
    bool? isSearching,
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
// Demo catalogue
// ─────────────────────────────────────────────────
final _recipeCatalogue = [
  const RecipeModel(
    id: 'sr1',
    title: 'Recipe Title',
    description: 'Short description of the recipe.',
    imageUrl: 'assets/images/rice_image.png',
    dietTags: ['Gluten Free', 'Label 01', 'Label 02'],
    servings: 2,
    timeOfPreparation: 30,
    freeOfIngredients: ['Label', 'Label', 'Label', 'Label'],
  ),
  const RecipeModel(
    id: 'sr2',
    title: 'Recipe Title',
    description: 'Short description of the recipe.',
    imageUrl: 'assets/images/rice_image.png',
    dietTags: ['Gluten Free', 'Label 01', 'Label 02'],
    servings: 2,
    timeOfPreparation: 30,
    freeOfIngredients: ['Label', 'Label', 'Label', 'Label'],
  ),
  const RecipeModel(
    id: 'sr3',
    title: 'Recipe Title',
    description: 'Short description of the recipe.',
    imageUrl: 'assets/images/rice_image.png',
    dietTags: ['Gluten Free', 'Label 01', 'Label 02'],
    servings: 2,
    timeOfPreparation: 30,
    freeOfIngredients: ['Label', 'Label', 'Label', 'Label'],
  ),
  const RecipeModel(
    id: 'sr4',
    title: 'Recipe Title',
    description: 'Short description of the recipe.',
    imageUrl: 'assets/images/rice_image.png',
    dietTags: ['Gluten Free', 'Label 01', 'Label 02'],
    servings: 2,
    timeOfPreparation: 30,
    freeOfIngredients: ['Label', 'Label', 'Label', 'Label'],
  ),
];

// ─────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────
class SearchRecipeNotifier extends StateNotifier<SearchRecipeState> {
  SearchRecipeNotifier() : super(const SearchRecipeState());

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
    final results = _recipeCatalogue
        .where(
          (r) =>
              r.title.toLowerCase().contains(query.toLowerCase()) ||
              r.dietTags.any(
                (t) => t.toLowerCase().contains(query.toLowerCase()),
              ),
        )
        .toList();
    state = state.copyWith(
      query: query,
      isSearching: true,
      results: results.isEmpty ? _recipeCatalogue : results,
    );
  }

  void clearSearch() {
    state = const SearchRecipeState();
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

  void toggleSave(String recipeId) {
    final updated = state.results.map((r) {
      if (r.id == recipeId) return r.copyWith(isSaved: !r.isSaved);
      return r;
    }).toList();
    state = state.copyWith(results: updated);
  }

  void updateFilter(SearchRecipeFilter filter) {
    state = state.copyWith(filter: filter);
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
