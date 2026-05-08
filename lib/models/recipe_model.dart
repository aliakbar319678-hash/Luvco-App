class RecipeModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final List<String> dietTags;
  final int timeOfPreparation; // minutes
  final int servings;
  final List<String> freeOfIngredients;
  final bool isSaved;

  const RecipeModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.dietTags = const [],
    this.timeOfPreparation = 30,
    this.servings = 2,
    this.freeOfIngredients = const [],
    this.isSaved = false,
  });

  RecipeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? dietTags,
    int? timeOfPreparation,
    int? servings,
    List<String>? freeOfIngredients,
    bool? isSaved,
  }) => RecipeModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    dietTags: dietTags ?? this.dietTags,
    timeOfPreparation: timeOfPreparation ?? this.timeOfPreparation,
    servings: servings ?? this.servings,
    freeOfIngredients: freeOfIngredients ?? this.freeOfIngredients,
    isSaved: isSaved ?? this.isSaved,
  );
}
