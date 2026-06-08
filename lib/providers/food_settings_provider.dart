import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/preference_api_service.dart';

class FoodSettingsState {
  final List<String> dietChoices;
  final List<String> challenges;
  final bool isLoading;
  final String? errorMessage;

  FoodSettingsState({
    this.dietChoices = const [],
    this.challenges = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  FoodSettingsState copyWith({
    List<String>? dietChoices,
    List<String>? challenges,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FoodSettingsState(
      dietChoices: dietChoices ?? this.dietChoices,
      challenges: challenges ?? this.challenges,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get isEmpty => dietChoices.isEmpty && challenges.isEmpty;
}

class FoodSettingsNotifier extends StateNotifier<FoodSettingsState> {
  final PreferenceApiService _api = PreferenceApiService.instance;

  FoodSettingsNotifier() : super(FoodSettingsState(isLoading: true)) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final prefs = await _api.getPreferences();
      state = FoodSettingsState(
        dietChoices: List<String>.from(prefs['dietTypes'] ?? []),
        challenges: List<String>.from(prefs['allergyTags'] ?? []),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void toggleDietChoice(String choice) async {
    final current = [...state.dietChoices];
    if (current.contains(choice)) {
      current.remove(choice);
    } else {
      current.add(choice);
    }
    state = state.copyWith(dietChoices: current);

    try {
      await _api.replaceDietTypes(current);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      // Reload from backend to sync back
      loadSettings();
    }
  }

  void toggleChallenge(String challenge) async {
    final current = [...state.challenges];
    if (current.contains(challenge)) {
      current.remove(challenge);
    } else {
      current.add(challenge);
    }
    state = state.copyWith(challenges: current);

    try {
      await _api.replaceAllergyTags(current);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      // Reload from backend to sync back
      loadSettings();
    }
  }

  void clearAll() async {
    state = FoodSettingsState(isLoading: true);
    try {
      await _api.replaceDietTypes([]);
      await _api.replaceAllergyTags([]);
      state = FoodSettingsState(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      loadSettings();
    }
  }
}

final foodSettingsProvider =
    StateNotifierProvider<FoodSettingsNotifier, FoodSettingsState>((ref) {
  return FoodSettingsNotifier();
});
