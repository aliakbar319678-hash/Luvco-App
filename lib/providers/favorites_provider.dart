import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shopping_list_detail_provider.dart';
import '../core/network/favorite_api_service.dart';

// ── Favorites State ────────────────────────────────────────────────
class FavoritesState {
  final List<ShoppingListItem> items;
  final bool isLoading;
  final String? errorMessage;

  const FavoritesState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  FavoritesState copyWith({
    List<ShoppingListItem>? items,
    bool? isLoading,
    String? errorMessage,
  }) =>
      FavoritesState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

// ── Favorites Notifier ─────────────────────────────────────────────
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier() : super(const FavoritesState()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await FavoriteApiService.instance.getFavorites();
      final items = list.map((e) {
        final barcode = e['barcode'] as String? ?? '';
        final productName = e['productName'] as String? ?? 'Product';
        final productImageUrl = e['productImageUrl'] as String?;
        final addedAt = e['addedAt'] as String? ?? '';
        final dateStr = addedAt.isNotEmpty ? addedAt.split('T').first : '';

        return ShoppingListItem(
          id: barcode, // use barcode as the unique ID for favorites
          barcode: barcode,
          name: productName,
          description: dateStr.isNotEmpty ? 'Added on: $dateStr' : 'Saved product',
          thumbnailAsset: productImageUrl,
        );
      }).toList();

      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addFavorite({
    required String barcode,
    required String productName,
    String? productImageUrl,
  }) async {
    try {
      await FavoriteApiService.instance.addFavorite(
        barcode: barcode,
        productName: productName,
        productImageUrl: productImageUrl,
      );
      await loadFavorites();
    } catch (e) {
      // Failed to add
      rethrow;
    }
  }

  Future<void> removeItem(String barcode) async {
    final originalItems = state.items;
    
    // Optimistic UI update
    state = state.copyWith(
      items: state.items.where((i) => i.barcode != barcode).toList(),
    );

    try {
      await FavoriteApiService.instance.deleteFavorite(barcode);
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(items: originalItems);
      rethrow;
    }
  }

  bool contains(String barcode) => state.items.any((i) => i.barcode == barcode);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>(
  (_) => FavoritesNotifier(),
);

// ── Filter sort option ─────────────────────────────────────────────
enum FavoritesSortOption { mostRecent, nameAZ }

final favoritesSortProvider =
    StateProvider<FavoritesSortOption>((_) => FavoritesSortOption.mostRecent);
