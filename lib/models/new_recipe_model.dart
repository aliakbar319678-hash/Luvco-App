// ─────────────────────────────────────────────────────────────────
// NewRecipeModel — holds all data for the 3-step new recipe flow
// ─────────────────────────────────────────────────────────────────

class AddedIngredient {
  final String id;
  final String name;
  final String otherData;
  final String? imageUrl;
  final bool isUnsustainable;

  const AddedIngredient({
    required this.id,
    required this.name,
    required this.otherData,
    this.imageUrl,
    this.isUnsustainable = false,
  });

  AddedIngredient copyWith({
    String? id,
    String? name,
    String? otherData,
    String? imageUrl,
    bool? isUnsustainable,
  }) => AddedIngredient(
    id: id ?? this.id,
    name: name ?? this.name,
    otherData: otherData ?? this.otherData,
    imageUrl: imageUrl ?? this.imageUrl,
    isUnsustainable: isUnsustainable ?? this.isUnsustainable,
  );
}

class NewRecipeModel {
  // Step 1
  final String? coverImagePath;
  final String recipeName;
  final String description;
  final String? timeOfPreparation;
  final String? servings;
  final List<String> selectedDietTypes;
  final List<String> selectedFreeIngredients;

  // Step 2
  final String ingredients;
  final String instructions;

  // Step 3
  final List<AddedIngredient> addedIngredients;

  const NewRecipeModel({
    this.coverImagePath,
    this.recipeName = '',
    this.description = '',
    this.timeOfPreparation,
    this.servings,
    this.selectedDietTypes = const [],
    this.selectedFreeIngredients = const [],
    this.ingredients = '',
    this.instructions = '',
    this.addedIngredients = const [],
  });

  NewRecipeModel copyWith({
    String? coverImagePath,
    String? recipeName,
    String? description,
    String? timeOfPreparation,
    String? servings,
    List<String>? selectedDietTypes,
    List<String>? selectedFreeIngredients,
    String? ingredients,
    String? instructions,
    List<AddedIngredient>? addedIngredients,
  }) => NewRecipeModel(
    coverImagePath: coverImagePath ?? this.coverImagePath,
    recipeName: recipeName ?? this.recipeName,
    description: description ?? this.description,
    timeOfPreparation: timeOfPreparation ?? this.timeOfPreparation,
    servings: servings ?? this.servings,
    selectedDietTypes: selectedDietTypes ?? this.selectedDietTypes,
    selectedFreeIngredients:
        selectedFreeIngredients ?? this.selectedFreeIngredients,
    ingredients: ingredients ?? this.ingredients,
    instructions: instructions ?? this.instructions,
    addedIngredients: addedIngredients ?? this.addedIngredients,
  );

  bool get isStep1Valid =>
      recipeName.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      timeOfPreparation != null &&
      servings != null;

  bool get isStep2Valid =>
      ingredients.trim().isNotEmpty && instructions.trim().isNotEmpty;
}
