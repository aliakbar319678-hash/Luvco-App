import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding_model.dart';

// ── All available diet options ───────────────────────────────────
const List<String> kDietOptions = [
  'Diet A',
  'Diet Name B',
  'Diet Type C',
  'Diet Name D',
  'Diet E',
  'Diet Name F',
  'Diet G',
  'Diet Type H',
  'Diet Type I',
  'Diet J',
  'Diet K',
  'Diet Name L',
];

// ── All available allergy/food challenge options ─────────────────
const List<String> kAllergyOptions = [
  'Allergy A',
  'Food Challenge B',
  'Food Challenge C',
  'Food F',
  'Allergy D',
  'Ingredient E',
  'Allergy G',
  'Food Challenge H',
  'Food I',
  'Allergy J',
];

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
