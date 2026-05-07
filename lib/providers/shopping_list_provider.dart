import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_list_model.dart';

// ── View mode toggle: grid or list ──────────────────────────────
enum ShoppingListViewMode { grid, list }

final viewModeProvider = StateProvider<ShoppingListViewMode>(
  (ref) => ShoppingListViewMode.grid,
);

// ── Active tab on profile screen ─────────────────────────────────
enum ProfileTab { shoppingLists, myRecipes, foodSettings }

final profileTabProvider = StateProvider<ProfileTab>(
  (ref) => ProfileTab.shoppingLists,
);

// ── Shopping lists state ─────────────────────────────────────────
class ShoppingListNotifier extends StateNotifier<List<ShoppingListModel>> {
  ShoppingListNotifier() : super(_demoLists);

  // Demo data — replace with real API calls
  static final _demoLists = [
    const ShoppingListModel(
      id: '1',
      title: 'List Title',
      description: 'Short description of the shopping list.',
      itemCount: 2,
      imageUrl: 'assets/images/bread_pic.png',
    ),
    const ShoppingListModel(
      id: '2',
      title: 'List Title',
      description: 'Short description of the shopping list.',
      itemCount: 2,
      imageUrl: 'assets/images/bread_pic.png',
    ),
    const ShoppingListModel(
      id: '3',
      title: 'List Title',
      description: 'Short description of the shopping list.',
      itemCount: 2,
      imageUrl: 'assets/images/bread_pic.png',
    ),
  ];

  // ── Add new list ─────────────────────────────────────────────
  void addList(ShoppingListModel list) {
    state = [...state, list];
  }

  // ── Edit existing list ───────────────────────────────────────
  void editList(String id, String newTitle, String newDescription) {
    state = state.map((list) {
      if (list.id == id) {
        return list.copyWith(title: newTitle, description: newDescription);
      }
      return list;
    }).toList();
  }

  // ── Duplicate list ───────────────────────────────────────────
  void duplicateList(String id) {
    final original = state.firstWhere((l) => l.id == id);
    final duplicate = ShoppingListModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${original.title} (Copy)',
      description: original.description,
      itemCount: original.itemCount,
      imageUrl: original.imageUrl,
    );
    state = [...state, duplicate];
  }

  // ── Delete list ──────────────────────────────────────────────
  void deleteList(String id) {
    state = state.where((l) => l.id != id).toList();
  }
}

final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, List<ShoppingListModel>>(
      (_) => ShoppingListNotifier(),
    );
