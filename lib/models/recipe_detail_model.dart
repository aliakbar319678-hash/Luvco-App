// ─────────────────────────────────────────────────────────────────
// RecipeDetailModel — full data model for Recipe Detail screen
// ─────────────────────────────────────────────────────────────────

class RecipeProduct {
  final String id;
  final String name;
  final String otherData;
  final String
  sustainabilityLevel; // 'Unsustainable' | 'Moderate Impact' | 'Eco-Friendly'
  final String safetyLevel; // 'Avoid' | 'Safe'
  final String? imageAsset;

  const RecipeProduct({
    required this.id,
    required this.name,
    required this.otherData,
    required this.sustainabilityLevel,
    required this.safetyLevel,
    this.imageAsset,
  });

  RecipeProduct copyWith({
    String? id,
    String? name,
    String? otherData,
    String? sustainabilityLevel,
    String? safetyLevel,
    String? imageAsset,
  }) => RecipeProduct(
    id: id ?? this.id,
    name: name ?? this.name,
    otherData: otherData ?? this.otherData,
    sustainabilityLevel: sustainabilityLevel ?? this.sustainabilityLevel,
    safetyLevel: safetyLevel ?? this.safetyLevel,
    imageAsset: imageAsset ?? this.imageAsset,
  );
}

class RecipeDetailModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final int servings;
  final int timeMinutes;
  final List<String> dietTypes;
  final List<String> freeOfIngredients;
  final String ingredients; // multi-line bullet text
  final String instructions; // multi-line numbered text
  final List<RecipeProduct> products;
  final bool isOwner; // owner can edit/duplicate/delete

  const RecipeDetailModel({
    required this.id,
    required this.title,
    this.description = '',
    this.imageUrl,
    this.servings = 2,
    this.timeMinutes = 30,
    this.dietTypes = const [],
    this.freeOfIngredients = const [],
    this.ingredients = '',
    this.instructions = '',
    this.products = const [],
    this.isOwner = true,
  });

  RecipeDetailModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    int? servings,
    int? timeMinutes,
    List<String>? dietTypes,
    List<String>? freeOfIngredients,
    String? ingredients,
    String? instructions,
    List<RecipeProduct>? products,
    bool? isOwner,
  }) => RecipeDetailModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    servings: servings ?? this.servings,
    timeMinutes: timeMinutes ?? this.timeMinutes,
    dietTypes: dietTypes ?? this.dietTypes,
    freeOfIngredients: freeOfIngredients ?? this.freeOfIngredients,
    ingredients: ingredients ?? this.ingredients,
    instructions: instructions ?? this.instructions,
    products: products ?? this.products,
    isOwner: isOwner ?? this.isOwner,
  );
}
