// ─────────────────────────────────────────────────────────────────
// FoodPreferencesModel — covers both Allergies and Diet screens
// ─────────────────────────────────────────────────────────────────

class FoodPreferenceItem {
  final String id;
  final String label;
  final bool isCustom; // custom items have edit + delete, selected have only delete
  final String? type;  // backend custom allergies carry a "type" field (e.g. "spice")
  final bool isActive; // backend supports toggling items on/off

  const FoodPreferenceItem({
    required this.id,
    required this.label,
    this.isCustom = false,
    this.type,
    this.isActive = true,
  });

  /// Parse a custom allergy/diet JSON object from the backend.
  ///
  /// Backend shape for custom allergies:
  ///   `{ "id": "uuid", "name": "Garlic", "type": "ingredient", "isActive": true }`
  /// Backend shape for custom diets:
  ///   `{ "id": "uuid", "name": "Keto", "isActive": true }`
  factory FoodPreferenceItem.fromJson(Map<String, dynamic> json) {
    return FoodPreferenceItem(
      id: json['id'] as String,
      label: json['name'] as String,
      isCustom: true,
      type: json['type'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Serialize for backend PUT/POST requests.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'name': label};
    if (type != null) map['type'] = type;
    return map;
  }

  FoodPreferenceItem copyWith({
    String? id,
    String? label,
    bool? isCustom,
    String? type,
    bool? isActive,
  }) =>
      FoodPreferenceItem(
        id: id ?? this.id,
        label: label ?? this.label,
        isCustom: isCustom ?? this.isCustom,
        type: type ?? this.type,
        isActive: isActive ?? this.isActive,
      );
}

class FoodPreferencesModel {
  final List<FoodPreferenceItem> selectedItems; // "Selected" tab items (preset tags)
  final List<FoodPreferenceItem> customItems;   // "Custom" tab items
  final bool isLoading;
  final String? errorMessage;

  const FoodPreferencesModel({
    this.selectedItems = const [],
    this.customItems = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Build a model from the backend `GET /users/me/preferences` response.
  ///
  /// [presetTagsKey] is either `"allergyTags"` or `"dietTypes"`.
  /// [customKey] is either `"customAllergies"` or `"customDiets"`.
  factory FoodPreferencesModel.fromApiResponse(
    Map<String, dynamic> data, {
    required String presetTagsKey,
    required String customKey,
  }) {
    // Preset tags are simple string arrays — convert to FoodPreferenceItem
    final presetTags = (data[presetTagsKey] as List<dynamic>?)
            ?.asMap()
            .entries
            .map(
              (e) => FoodPreferenceItem(
                id: 'preset_${e.key}_${e.value}',
                label: e.value as String,
              ),
            )
            .toList() ??
        [];

    // Custom items are object arrays with id/name/type/isActive
    final customItems = (data[customKey] as List<dynamic>?)
            ?.map(
              (e) => FoodPreferenceItem.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];

    return FoodPreferencesModel(
      selectedItems: presetTags,
      customItems: customItems,
    );
  }

  FoodPreferencesModel copyWith({
    List<FoodPreferenceItem>? selectedItems,
    List<FoodPreferenceItem>? customItems,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) => FoodPreferencesModel(
    selectedItems: selectedItems ?? this.selectedItems,
    customItems: customItems ?? this.customItems,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}
