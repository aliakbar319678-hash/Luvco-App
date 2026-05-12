// ─────────────────────────────────────────────────────────────────
// FoodPreferencesModel — covers both Allergies and Diet screens
// ─────────────────────────────────────────────────────────────────

class FoodPreferenceItem {
  final String id;
  final String label;
  final bool
  isCustom; // custom items have edit + delete, selected have only delete

  const FoodPreferenceItem({
    required this.id,
    required this.label,
    this.isCustom = false,
  });

  FoodPreferenceItem copyWith({String? id, String? label, bool? isCustom}) =>
      FoodPreferenceItem(
        id: id ?? this.id,
        label: label ?? this.label,
        isCustom: isCustom ?? this.isCustom,
      );
}

class FoodPreferencesModel {
  final List<FoodPreferenceItem> selectedItems; // "Selected" tab items
  final List<FoodPreferenceItem> customItems; // "Custom" tab items

  const FoodPreferencesModel({
    this.selectedItems = const [],
    this.customItems = const [],
  });

  FoodPreferencesModel copyWith({
    List<FoodPreferenceItem>? selectedItems,
    List<FoodPreferenceItem>? customItems,
  }) => FoodPreferencesModel(
    selectedItems: selectedItems ?? this.selectedItems,
    customItems: customItems ?? this.customItems,
  );
}
