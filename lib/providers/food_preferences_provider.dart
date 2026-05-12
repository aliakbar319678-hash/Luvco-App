import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_preferences_model.dart';

// ── Active tab: 0=Selected, 1=Custom ──────────────────────────────
final foodPrefsTabProvider = StateProvider.autoDispose<int>((_) => 0);

// ── Search modal visibility ────────────────────────────────────────
final foodPrefsSearchModalProvider = StateProvider.autoDispose<bool>(
  (_) => false,
);

// ── Add Manually modal visibility ─────────────────────────────────
final foodPrefsAddManuallyModalProvider = StateProvider.autoDispose<bool>(
  (_) => false,
);

// ── Edit custom item — holds the item being edited (null = none) ──
final foodPrefsEditItemProvider =
    StateProvider.autoDispose<FoodPreferenceItem?>((_) => null);

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

// ── Mock data for search results ──────────────────────────────────
const _mockAllergySearchResults = ['Allergen 01', 'Allergen 01', 'Allergen 01'];

const _mockDietSearchResults = ['Diet 01', 'Diet 01', 'Diet 01'];

// ── Food Preferences Notifier ──────────────────────────────────────
class FoodPreferencesNotifier extends StateNotifier<FoodPreferencesModel> {
  FoodPreferencesNotifier()
    : super(
        const FoodPreferencesModel(
          selectedItems: [
            FoodPreferenceItem(id: 's1', label: 'Allergen 01'),
            FoodPreferenceItem(id: 's2', label: 'Allergen 01'),
            FoodPreferenceItem(id: 's3', label: 'Allergen 01'),
          ],
          customItems: [
            FoodPreferenceItem(id: 'c1', label: 'Allergen 01', isCustom: true),
            FoodPreferenceItem(id: 'c2', label: 'Allergen 01', isCustom: true),
            FoodPreferenceItem(id: 'c3', label: 'Allergen 01', isCustom: true),
          ],
        ),
      );

  // ── Selected tab ──
  void addSelectedItems(List<String> labels) {
    final existing = List<FoodPreferenceItem>.from(state.selectedItems);
    for (final label in labels) {
      final id = '${DateTime.now().millisecondsSinceEpoch}_$label';
      if (!existing.any((e) => e.label == label)) {
        existing.add(FoodPreferenceItem(id: id, label: label));
      }
    }
    state = state.copyWith(selectedItems: existing);
  }

  void deleteSelectedItem(String id) {
    state = state.copyWith(
      selectedItems: state.selectedItems.where((e) => e.id != id).toList(),
    );
  }

  // ── Custom tab ──
  void addCustomItems(List<String> labels) {
    final existing = List<FoodPreferenceItem>.from(state.customItems);
    for (final label in labels) {
      if (label.trim().isEmpty) continue;
      final id = '${DateTime.now().millisecondsSinceEpoch}_$label';
      existing.add(FoodPreferenceItem(id: id, label: label, isCustom: true));
    }
    state = state.copyWith(customItems: existing);
  }

  void editCustomItem(String id, String newLabel) {
    state = state.copyWith(
      customItems: state.customItems
          .map((e) => e.id == id ? e.copyWith(label: newLabel) : e)
          .toList(),
    );
  }

  void deleteCustomItem(String id) {
    state = state.copyWith(
      customItems: state.customItems.where((e) => e.id != id).toList(),
    );
  }
}

// ── Two separate providers: one for allergies, one for diet ────────
final foodAllergiesProvider =
    StateNotifierProvider<FoodPreferencesNotifier, FoodPreferencesModel>(
      (_) => FoodPreferencesNotifier(),
    );

final foodDietProvider =
    StateNotifierProvider<FoodPreferencesNotifier, FoodPreferencesModel>(
      (_) => FoodPreferencesNotifier(),
    );

List<String> getMockSearchResults(bool isDiet) =>
    isDiet ? _mockDietSearchResults : _mockAllergySearchResults;
