import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/recipe_model.dart';
import '../models/shopping_list_model.dart';
import 'favorites_provider.dart';
import '../core/network/product_api_service.dart';
import '../core/network/recipe_api_service.dart';
import '../core/network/list_api_service.dart';

// ─────────────────────────────────────────────────────────────────
// Filter state
// ─────────────────────────────────────────────────────────────────
class DashboardSearchFilter {
  final String sortBy; // 'Most Recent', 'A-Z', etc.
  final List<String> filter2Tags;
  final List<String> filter3Tags;

  const DashboardSearchFilter({
    this.sortBy = 'Most Recent',
    this.filter2Tags = const [],
    this.filter3Tags = const [],
  });

  DashboardSearchFilter copyWith({
    String? sortBy,
    List<String>? filter2Tags,
    List<String>? filter3Tags,
  }) =>
      DashboardSearchFilter(
        sortBy: sortBy ?? this.sortBy,
        filter2Tags: filter2Tags ?? this.filter2Tags,
        filter3Tags: filter3Tags ?? this.filter3Tags,
      );
}

// ─────────────────────────────────────────────────────────────────
// Sustainability badge pair model
// ─────────────────────────────────────────────────────────────────
class ProductBadgePair {
  final String ecoLabel;   // e.g. 'Unsustainable', 'Eco-Friendly', 'Moderate Impact'
  final String safetyLabel; // e.g. 'Avoid', 'Safe'

  const ProductBadgePair({required this.ecoLabel, required this.safetyLabel});
}

// Color helpers (used by UI) — pixel-perfect per Figma
const _ecoColors = {
  'Unsustainable': 0xFFE12C2C,   // Vibrant Figma red
  'Moderate Impact': 0xFFFFB800, // Figma yellow/orange
  'Eco-Friendly': 0xFF4CAF50,    // Figma green
  'Safe': 0xFF4CAF50,            // Figma green
  'Avoid': 0xFFFFB800,           // Figma yellow/orange
};

int ecoColorFor(String label) => _ecoColors[label] ?? 0xFF9E9E9E;

// ─────────────────────────────────────────────────────────────────
// Search result item
// ─────────────────────────────────────────────────────────────────
class DashboardSearchResult {
  final ProductModel product;
  final ProductBadgePair badges;
  bool isFavorite;

  DashboardSearchResult({
    required this.product,
    required this.badges,
    this.isFavorite = false,
  });
}

// ─────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────
class DashboardSearchState {
  final String query;
  final bool isSearching;
  final List<DashboardSearchResult> results;
  final DashboardSearchFilter filter;
  final List<ShoppingListModel> shoppingLists;
  final List<RecipeModel> recipes;

  const DashboardSearchState({
    this.query = '',
    this.isSearching = false,
    this.results = const [],
    this.filter = const DashboardSearchFilter(),
    this.shoppingLists = const [],
    this.recipes = const [],
  });

  DashboardSearchState copyWith({
    String? query,
    bool? isSearching,
    List<DashboardSearchResult>? results,
    DashboardSearchFilter? filter,
    List<ShoppingListModel>? shoppingLists,
    List<RecipeModel>? recipes,
  }) =>
      DashboardSearchState(
        query: query ?? this.query,
        isSearching: isSearching ?? this.isSearching,
        results: results ?? this.results,
        filter: filter ?? this.filter,
        shoppingLists: shoppingLists ?? this.shoppingLists,
        recipes: recipes ?? this.recipes,
      );
}



// ─────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────
class DashboardSearchNotifier extends StateNotifier<DashboardSearchState> {
  final Ref _ref;

  DashboardSearchNotifier(this._ref) : super(const DashboardSearchState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadRecipes(), _loadShoppingLists()]);
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await RecipeApiService.instance.getRecipes('my-recipes');
      state = state.copyWith(recipes: recipes);
    } catch (_) {
      // Keep empty list if loading fails
    }
  }

  Future<void> _loadShoppingLists() async {
    try {
      final lists = await ListApiService.instance.getLists();
      state = state.copyWith(shoppingLists: lists);
    } catch (_) {
      // Keep empty list if loading fails
    }
  }

  Future<void> onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(query: '', isSearching: false, results: []);
      return;
    }
    
    state = state.copyWith(query: query, isSearching: true, results: []);
    
    try {
      final products = await ProductApiService.instance.searchProducts(query);
      
      // If query changed while we were fetching, ignore this result
      if (state.query != query) return;
      
      final favorites = _ref.read(favoritesProvider).items;
      final results = products.map((p) {
        final isFav = favorites.any((i) => i.barcode == p.id);
        return DashboardSearchResult(
          product: p,
          badges: ProductBadgePair(
            ecoLabel: p.sustainabilityLabel,
            safetyLabel: p.safetyLabel,
          ),
          isFavorite: isFav,
        );
      }).toList();
      
      state = state.copyWith(
        results: _applySortFilter(results, state.filter),
        isSearching: false,
      );
    } catch (e) {
      if (state.query == query) {
        state = state.copyWith(results: [], isSearching: false);
      }
    }
  }

  List<DashboardSearchResult> _applySortFilter(
    List<DashboardSearchResult> results,
    DashboardSearchFilter filter,
  ) {
    final sorted = List<DashboardSearchResult>.from(results);
    switch (filter.sortBy) {
      case 'A-Z':
        sorted.sort((a, b) => a.product.name.toLowerCase().compareTo(b.product.name.toLowerCase()));
        break;
      case 'Z-A':
        sorted.sort((a, b) => b.product.name.toLowerCase().compareTo(a.product.name.toLowerCase()));
        break;
      case 'Eco Score':
        const order = {'Eco-Friendly': 0, 'Moderate Impact': 1, 'Unsustainable': 2};
        sorted.sort((a, b) =>
            (order[a.badges.ecoLabel] ?? 1).compareTo(order[b.badges.ecoLabel] ?? 1));
        break;
      default: // 'Most Recent' — keep original order
        break;
    }
    return sorted;
  }

  void clearSearch() {
    state = state.copyWith(query: '', isSearching: false, results: []);
  }

  Future<void> toggleFavorite(String productId) async {
    final favorites = _ref.read(favoritesProvider).items;
    final isFav = favorites.any((i) => i.barcode == productId);
    
    final result = state.results.firstWhere((r) => r.product.id == productId);

    try {
      if (isFav) {
        await _ref.read(favoritesProvider.notifier).removeItem(productId);
      } else {
        await _ref.read(favoritesProvider.notifier).addFavorite(
          barcode: productId,
          productName: result.product.name,
          productImageUrl: result.product.thumbnailAsset,
        );
      }
      
      final updated = state.results.map((r) {
        if (r.product.id == productId) {
          return DashboardSearchResult(
            product: r.product,
            badges: r.badges,
            isFavorite: !isFav,
          );
        }
        return r;
      }).toList();
      state = state.copyWith(results: updated);
    } catch (_) {
      // Ignore error
    }
  }

  void updateFilter(DashboardSearchFilter filter) {
    final sorted = _applySortFilter(state.results, filter);
    state = state.copyWith(filter: filter, results: sorted);
  }

  void reset() => state = const DashboardSearchState();
}

final dashboardSearchProvider = StateNotifierProvider.autoDispose<
    DashboardSearchNotifier, DashboardSearchState>(
  (ref) => DashboardSearchNotifier(ref),
);
