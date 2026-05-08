import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoodSettingsState {
  final List<String> dietChoices;
  final List<String> challenges;

  FoodSettingsState({
    this.dietChoices = const [],
    this.challenges = const [],
  });

  FoodSettingsState copyWith({
    List<String>? dietChoices,
    List<String>? challenges,
  }) {
    return FoodSettingsState(
      dietChoices: dietChoices ?? this.dietChoices,
      challenges: challenges ?? this.challenges,
    );
  }

  bool get isEmpty => dietChoices.isEmpty && challenges.isEmpty;
}

class FoodSettingsNotifier extends StateNotifier<FoodSettingsState> {
  FoodSettingsNotifier() : super(FoodSettingsState());

  void toggleDietChoice(String choice) {
    final current = [...state.dietChoices];
    if (current.contains(choice)) {
      current.remove(choice);
    } else {
      current.add(choice);
    }
    state = state.copyWith(dietChoices: current);
  }

  void toggleChallenge(String challenge) {
    final current = [...state.challenges];
    if (current.contains(challenge)) {
      current.remove(challenge);
    } else {
      current.add(challenge);
    }
    state = state.copyWith(challenges: current);
  }

  void clearAll() {
    state = FoodSettingsState();
  }
}

final foodSettingsProvider =
    StateNotifierProvider<FoodSettingsNotifier, FoodSettingsState>((ref) {
  return FoodSettingsNotifier();
});
