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

  // ── Edit existing list (title/description) ───────────────────────
  Future<void> editList(String listId, String title, String description) async {
    try {
      final updated = await ListApiService.instance.editList(listId, title: title, description: description);
      // replace the matching list in state
      state = state.map((list) => list.id == listId ? updated : list).toList();
    } catch (e) {
      // handle error silently or log
    }
  }



  // ── Delete existing list ───────────────────────────────────────
  Future<void> deleteList(String listId) async {
    try {
      await ListApiService.instance.deleteList(listId);
      state = state.where((list) => list.id != listId).toList();
    } catch (e) {
      // handle error silently or log
    }
  }
  Future<void> duplicateList(String id) async {
    try {
      final newList = await ListApiService.instance.duplicateList(id);
      state = [...state, newList];
      await loadLists();
    } catch (e) {
      // Handle error
    }
  }

  // Update list item count when items change in detail view
  void setItemCount(String listId, int count) {
    state = state.map((list) {
      if (list.id == listId) {
        return list.copyWith(itemCount: count);
      }
      return list;
    }).toList();
  }
}

final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, List<ShoppingListModel>>(
      (_) => ShoppingListNotifier(),
    );
