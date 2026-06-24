import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../core/network/product_api_service.dart';

class SearchProductFilter {
  final String sortBy; // 'Most Recent', 'A-Z', etc.
  final List<String> filter2Tags;
  final List<String> filter3Tags;

  const SearchProductFilter({
    this.sortBy = 'Most Recent',
    this.filter2Tags = const [],
    this.filter3Tags = const [],
  });

  SearchProductFilter copyWith({
    String? sortBy,
    List<String>? filter2Tags,
    List<String>? filter3Tags,
  }) =>
      SearchProductFilter(
        sortBy: sortBy ?? this.sortBy,
        filter2Tags: filter2Tags ?? this.filter2Tags,
        filter3Tags: filter3Tags ?? this.filter3Tags,
      );
}

class SearchProductState {
  final String query;
  final bool isSearching;
  final List<ProductModel> results;
  final SearchProductFilter filter;

  const SearchProductState({
    this.query = '',
    this.isSearching = false,
    this.results = const [],
    this.filter = const SearchProductFilter(),
  });

  SearchProductState copyWith({
    String? query,
    bool? isSearching,
    List<ProductModel>? results,
    SearchProductFilter? filter,
  }) =>
      SearchProductState(
        query: query ?? this.query,
        isSearching: isSearching ?? this.isSearching,
        results: results ?? this.results,
        filter: filter ?? this.filter,
      );
}

class SearchProductNotifier extends StateNotifier<SearchProductState> {
  SearchProductNotifier() : super(const SearchProductState());

  List<ProductModel> _allResults = [];

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _allResults = [];
      state = state.copyWith(query: '', isSearching: false, results: []);
      return;
    }

    state = state.copyWith(query: query, isSearching: true, results: []);

    try {
      final products = await ProductApiService.instance.searchProducts(query);
      if (mounted) {
        if (state.query != query) return;
        _allResults = products;
        state = state.copyWith(
          results: _applySortFilter(_allResults, state.filter),
          isSearching: false,
        );
      }
    } catch (e) {
      if (mounted) {
        if (state.query == query) {
          state = state.copyWith(isSearching: false, results: []);
        }
      }
    }
  }

  void updateFilter(SearchProductFilter filter) {
    final sorted = _applySortFilter(_allResults, filter);
    state = state.copyWith(filter: filter, results: sorted);
  }

  List<ProductModel> _applySortFilter(
    List<ProductModel> results,
    SearchProductFilter filter,
  ) {
    var filtered = List<ProductModel>.from(results);

    if (filter.filter2Tags.isNotEmpty) {
      filtered = filtered.where((r) => filter.filter2Tags.contains(r.sustainabilityLabel)).toList();
    }

    if (filter.filter3Tags.isNotEmpty) {
      filtered = filtered.where((r) => filter.filter3Tags.contains(r.safetyLabel)).toList();
    }

    switch (filter.sortBy) {
      case 'A-Z':
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'Z-A':
        filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'Eco Score':
        const order = {'Eco-Friendly': 0, 'Moderate Impact': 1, 'Unsustainable': 2};
        filtered.sort((a, b) =>
            (order[a.sustainabilityLabel] ?? 1).compareTo(order[b.sustainabilityLabel] ?? 1));
        break;
      default:
        break;
    }
    return filtered;
  }

  void clear() {
    _allResults = [];
    state = const SearchProductState();
  }
}

final searchProductProvider =
    StateNotifierProvider.autoDispose<SearchProductNotifier, SearchProductState>(
  (_) => SearchProductNotifier(),
);
