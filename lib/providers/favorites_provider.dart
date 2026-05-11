import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shopping_list_detail_provider.dart';

// ── Favorites State ────────────────────────────────────────────────
class FavoritesState {
  final List<ShoppingListItem> items;

  const FavoritesState({this.items = const []});

  FavoritesState copyWith({List<ShoppingListItem>? items}) =>
      FavoritesState(items: items ?? this.items);
}

// ── Favorites Notifier ─────────────────────────────────────────────
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier()
      : super(FavoritesState(items: _demoFavorites));

  static final _demoFavorites = [
    const ShoppingListItem(
      id: 'f1',
      name: 'Name of the Product',
      description: 'Other data related from the product.',
      thumbnailAsset: 'assets/images/cruesli_image.png',
    ),
    const ShoppingListItem(
      id: 'f2',
      name: 'Name of the Product',
      description: 'Other data related from the product.',
      thumbnailAsset: 'assets/images/cruesli_image.png',
    ),
    const ShoppingListItem(
      id: 'f3',
      name: 'Name of the Product',
      description: 'Other data related from the product.',
      thumbnailAsset: 'assets/images/cruesli_image.png',
    ),
    const ShoppingListItem(
      id: 'f4',
      name: 'Name of the Product',
      description: 'Other data related from the product.',
      thumbnailAsset: 'assets/images/cruesli_image.png',
    ),
  ];

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
    );
  }

  bool contains(String id) => state.items.any((i) => i.id == id);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>(
  (_) => FavoritesNotifier(),
);

// ── Filter sort option ─────────────────────────────────────────────
enum FavoritesSortOption { mostRecent, nameAZ }

final favoritesSortProvider =
    StateProvider<FavoritesSortOption>((_) => FavoritesSortOption.mostRecent);
