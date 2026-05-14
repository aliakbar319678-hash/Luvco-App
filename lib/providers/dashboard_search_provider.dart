import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';

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
  final List<String> shoppingLists;
  final List<String> recipes;

  const DashboardSearchState({
    this.query = '',
    this.isSearching = false,
    this.results = const [],
    this.filter = const DashboardSearchFilter(),
    this.shoppingLists = const ['Shopping List 01', 'Shopping List 02', 'Shopping List 03', 'Shopping List 04'],
    this.recipes = const ['Recipe 01', 'Recipe 02', 'Recipe 03'],
  });

  DashboardSearchState copyWith({
    String? query,
    bool? isSearching,
    List<DashboardSearchResult>? results,
    DashboardSearchFilter? filter,
    List<String>? shoppingLists,
    List<String>? recipes,
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
// Demo catalogue with badge pairs
// ─────────────────────────────────────────────────────────────────
final _catalogue = [
  DashboardSearchResult(
    product: const ProductModel(
      id: 'ds1',
      name: 'Name of the Product',
      description: 'Other data from the product.',
      thumbnailAsset: 'assets/images/nutila.png',
      imageAsset: 'assets/images/nutila.png',
      labels: ['Label', 'Label', 'Label', 'Label'],
      allergens: ['Label', 'Label', 'Label', 'Label'],
      isSustainable: false,
    ),
    badges: const ProductBadgePair(ecoLabel: 'Unsustainable', safetyLabel: 'Avoid'),
  ),
  DashboardSearchResult(
    product: const ProductModel(
      id: 'ds2',
      name: 'Name of the Product',
      description: 'Other data from the product.',
      thumbnailAsset: 'assets/images/nutila.png',
      imageAsset: 'assets/images/nutila.png',
      labels: ['Label', 'Label', 'Label', 'Label'],
      allergens: ['Label', 'Label', 'Label', 'Label'],
      isSustainable: true,
    ),
    badges: const ProductBadgePair(ecoLabel: 'Moderate Impact', safetyLabel: 'Safe'),
  ),
  DashboardSearchResult(
    product: const ProductModel(
      id: 'ds3',
      name: 'Name of the Product',
      description: 'Other data from the product.',
      thumbnailAsset: 'assets/images/nutila.png',
      imageAsset: 'assets/images/nutila.png',
      labels: ['Label', 'Label', 'Label', 'Label'],
      allergens: ['Label', 'Label', 'Label', 'Label'],
      isSustainable: true,
    ),
    badges: const ProductBadgePair(ecoLabel: 'Eco-Friendly', safetyLabel: 'Safe'),
  ),
];

// ─────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────
class DashboardSearchNotifier extends StateNotifier<DashboardSearchState> {
  DashboardSearchNotifier() : super(const DashboardSearchState());

  void onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      state = state.copyWith(query: '', isSearching: false, results: []);
      return;
    }
    final results = _catalogue
        .where((r) => r.product.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    state = state.copyWith(
      query: query,
      isSearching: true,
      results: results.isEmpty ? _catalogue : results,
    );
  }

  void clearSearch() {
    state = state.copyWith(query: '', isSearching: false, results: []);
  }

  void toggleFavorite(String productId) {
    final updated = state.results.map((r) {
      if (r.product.id == productId) {
        return DashboardSearchResult(
          product: r.product,
          badges: r.badges,
          isFavorite: !r.isFavorite,
        );
      }
      return r;
    }).toList();
    state = state.copyWith(results: updated);
  }

  void updateFilter(DashboardSearchFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void reset() => state = const DashboardSearchState();
}

final dashboardSearchProvider = StateNotifierProvider.autoDispose<
    DashboardSearchNotifier, DashboardSearchState>(
  (_) => DashboardSearchNotifier(),
);
