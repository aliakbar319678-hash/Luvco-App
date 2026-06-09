import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../core/network/product_api_service.dart';

class SearchProductState {
  final String query;
  final bool isSearching;
  final List<ProductModel> results;

  const SearchProductState({
    this.query = '',
    this.isSearching = false,
    this.results = const [],
  });

  SearchProductState copyWith({
    String? query,
    bool? isSearching,
    List<ProductModel>? results,
  }) =>
      SearchProductState(
        query: query ?? this.query,
        isSearching: isSearching ?? this.isSearching,
        results: results ?? this.results,
      );
}

class SearchProductNotifier extends StateNotifier<SearchProductState> {
  SearchProductNotifier() : super(const SearchProductState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(query: '', isSearching: false, results: []);
      return;
    }

    state = state.copyWith(query: query, isSearching: true);

    try {
      final products = await ProductApiService.instance.searchProducts(query);
      state = state.copyWith(results: products);
    } catch (e) {
      // Fail silently
    }
  }

  void clear() {
    state = const SearchProductState();
  }
}

final searchProductProvider =
    StateNotifierProvider.autoDispose<SearchProductNotifier, SearchProductState>(
  (_) => SearchProductNotifier(),
);
