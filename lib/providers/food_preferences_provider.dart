import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/preference_api_service.dart';
import '../models/food_preferences_model.dart';

// ── Active tab: 0=Selected, 1=Custom ──────────────────────────────
final foodPrefsTabProvider = StateProvider.autoDispose<int>((_) => 0);

// ── Delete confirm item — holds item pending deletion ─────────────
final foodPrefsDeleteItemProvider =
    StateProvider.autoDispose<FoodPreferenceItem?>((_) => null);

// ── Success toast ─────────────────────────────────────────────────
final foodPrefsSuccessProvider = StateProvider.autoDispose<bool>((_) => false);

// ── Search query inside search modal ──────────────────────────────
final foodPrefsSearchQueryProvider = StateProvider.autoDispose<String>(
  (_) => '',
);

// ── Selected items inside the search modal (chips) ────────────────
final foodPrefsSearchSelectedProvider = StateProvider.autoDispose<List<String>>(
  (_) => [],
);

// ── Onboarding preset tags (fetched from GET /content/onboarding) ─
final onboardingTagsProvider =
    FutureProvider<Map<String, List<String>>>((ref) async {
  return PreferenceApiService.instance.getOnboardingTags();
});

// ── Food Preferences Notifier ──────────────────────────────────────
class FoodPreferencesNotifier extends StateNotifier<FoodPreferencesModel> {
  final bool isDiet;
  final PreferenceApiService _api = PreferenceApiService.instance;

  FoodPreferencesNotifier({required this.isDiet})
    : super(const FoodPreferencesModel(isLoading: true)) {
    loadFromBackend();
  }

  /// Fetch preferences from the backend and populate state.
  Future<void> loadFromBackend() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final prefs = await _api.getPreferences();
      state = FoodPreferencesModel.fromApiResponse(
        prefs,
        presetTagsKey: isDiet ? 'dietTypes' : 'allergyTags',
        customKey: isDiet ? 'customDiets' : 'customAllergies',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // ── Selected tab (preset tags) ──

  /// Adds preset tags and syncs with the backend via PUT.
  void addSelectedItems(List<String> labels) async {
    final existing = List<FoodPreferenceItem>.from(state.selectedItems);
    for (final label in labels) {
      final id = 'preset_${DateTime.now().millisecondsSinceEpoch}_$label';
      if (!existing.any((e) => e.label == label)) {
        existing.add(FoodPreferenceItem(id: id, label: label));
      }
    }
    state = state.copyWith(selectedItems: existing);

    // Sync full list to backend
    final allLabels = existing.map((e) => e.label).toList();
    try {
      if (isDiet) {
        await _api.replaceDietTypes(allLabels);
      } else {
        await _api.replaceAllergyTags(allLabels);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Removes a preset tag and syncs with the backend via PUT.
  void deleteSelectedItem(String id) async {
    final updated =
        state.selectedItems.where((e) => e.id != id).toList();
    state = state.copyWith(selectedItems: updated);

    final allLabels = updated.map((e) => e.label).toList();
    try {
      if (isDiet) {
        await _api.replaceDietTypes(allLabels);
      } else {
        await _api.replaceAllergyTags(allLabels);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // ── Custom tab ──

  /// Adds custom items one by one via POST.
  void addCustomItems(List<String> labels) async {
    for (final label in labels) {
      if (label.trim().isEmpty) continue;
      try {
        List<dynamic> updated;
        if (isDiet) {
          updated = await _api.addCustomDiet(name: label.trim());
        } else {
          updated = await _api.addCustomAllergy(
            name: label.trim(),
            type: 'custom',
          );
        }
        // Re-parse the backend response into our model
        final customItems = updated
            .map((e) =>
                FoodPreferenceItem.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(customItems: customItems);
      } catch (e) {
        state = state.copyWith(errorMessage: e.toString());
      }
    }
  }

  /// Edits a custom item via PATCH.
  void editCustomItem(String id, String newLabel) async {
    // Optimistic UI update
    state = state.copyWith(
      customItems: state.customItems
          .map((e) => e.id == id ? e.copyWith(label: newLabel) : e)
          .toList(),
    );

    try {
      if (isDiet) {
        await _api.patchCustomDiet(id, name: newLabel);
      } else {
        await _api.patchCustomAllergy(id, name: newLabel);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      // Reload on error to restore correct state
      await loadFromBackend();
    }
  }

  /// Deletes a custom item via DELETE.
  void deleteCustomItem(String id) async {
    // Optimistic UI update
    final updated = state.customItems.where((e) => e.id != id).toList();
    state = state.copyWith(customItems: updated);

    try {
      if (isDiet) {
        await _api.deleteCustomDiet(id);
      } else {
        await _api.deleteCustomAllergy(id);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      await loadFromBackend();
    }
  }
}

// ── Two separate providers: one for allergies, one for diet ────────
final foodAllergiesProvider =
    StateNotifierProvider.autoDispose<FoodPreferencesNotifier, FoodPreferencesModel>(
      (_) => FoodPreferencesNotifier(isDiet: false),
    );

final foodDietProvider =
    StateNotifierProvider.autoDispose<FoodPreferencesNotifier, FoodPreferencesModel>(
      (_) => FoodPreferencesNotifier(isDiet: true),
    );
