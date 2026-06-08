import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/preference_api_service.dart';
import '../models/onboarding_model.dart';

// ── Fetch real allergy & diet options from GET /content/onboarding ─
final onboardingOptionsProvider =
    FutureProvider<Map<String, List<String>>>((ref) async {
  return PreferenceApiService.instance.getOnboardingTags();
});

// ── Onboarding state notifier ────────────────────────────────────
class OnboardingNotifier extends StateNotifier<OnboardingModel> {
  OnboardingNotifier() : super(const OnboardingModel());

  // Toggle diet selection
  void toggleDiet(String diet) {
    final current = List<String>.from(state.selectedDiets);
    current.contains(diet) ? current.remove(diet) : current.add(diet);
    state = state.copyWith(selectedDiets: current);
  }

  // Toggle allergy selection
  void toggleAllergy(String allergy) {
    final current = List<String>.from(state.selectedAllergies);
    current.contains(allergy) ? current.remove(allergy) : current.add(allergy);
    state = state.copyWith(selectedAllergies: current);
  }

  // Add manual allergy entry
  void addManualAllergy(String value) {
    if (value.trim().isEmpty) return;
    final current = List<String>.from(state.manualAllergies);
    if (!current.contains(value.trim())) current.add(value.trim());
    state = state.copyWith(manualAllergies: current);
  }

  // Remove manual allergy entry
  void removeManualAllergy(String value) {
    final current = List<String>.from(state.manualAllergies)..remove(value);
    state = state.copyWith(manualAllergies: current);
  }

  /// Save all onboarding selections to the backend.
  ///
  /// Calls three endpoints to persist:
  /// 1. Preset allergy tags → PUT /users/me/preferences/allergies
  /// 2. Preset diet types  → PUT /users/me/preferences/diets
  /// 3. Custom allergies (manual entries) → PUT /users/me/preferences/allergies/custom
  Future<bool> submitPreferences() async {
    final api = PreferenceApiService.instance;
    try {
      // Save preset allergy tags
      if (state.selectedAllergies.isNotEmpty) {
        await api.replaceAllergyTags(state.selectedAllergies);
      }

      // Save preset diet types
      if (state.selectedDiets.isNotEmpty) {
        await api.replaceDietTypes(state.selectedDiets);
      }

      // Save manual/custom allergies
      if (state.manualAllergies.isNotEmpty) {
        final customItems = state.manualAllergies
            .map((name) => {'name': name, 'type': 'custom'})
            .toList();
        await api.replaceCustomAllergies(customItems);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  void reset() => state = const OnboardingModel();
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingModel>(
      (_) => OnboardingNotifier(),
    );

// ── Manual allergy text field controller value ───────────────────
final manualAllergyInputProvider = StateProvider<String>((ref) => '');

// ── Show manual input field toggle ──────────────────────────────
final showManualInputProvider = StateProvider<bool>((ref) => false);
