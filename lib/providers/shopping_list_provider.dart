import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_list_model.dart';
import '../core/network/list_api_service.dart';

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
  ShoppingListNotifier() : super([]) {
    loadLists();
  }

  // ── Load lists from backend ──────────────────────────────────
  Future<void> loadLists() async {
    try {
      final lists = await ListApiService.instance.getLists();
      state = lists;
    } catch (e) {
      // Failed silently or logged
    }
  }

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
  Future<void> duplicateList(String id) async {
    try {
      final newList = await ListApiService.instance.duplicateList(id);
      state = [...state, newList];
      await loadLists();
    } catch (e) {
      // Handle error
    }
  }

  // ── Delete list ──────────────────────────────────────────────
  Future<void> deleteList(String id) async {
    try {
      await ListApiService.instance.deleteList(id);
      state = state.where((l) => l.id != id).toList();
    } catch (e) {
      // Handle error
    }
  }
}

final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, List<ShoppingListModel>>(
      (_) => ShoppingListNotifier(),
    );
