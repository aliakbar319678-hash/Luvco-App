class OnboardingModel {
  final List<String> selectedDiets;
  final List<String> selectedAllergies;
  final List<String> manualAllergies;

  const OnboardingModel({
    this.selectedDiets = const [],
    this.selectedAllergies = const [],
    this.manualAllergies = const [],
  });

  OnboardingModel copyWith({
    List<String>? selectedDiets,
    List<String>? selectedAllergies,
    List<String>? manualAllergies,
  }) => OnboardingModel(
    selectedDiets: selectedDiets ?? this.selectedDiets,
    selectedAllergies: selectedAllergies ?? this.selectedAllergies,
    manualAllergies: manualAllergies ?? this.manualAllergies,
  );
}
