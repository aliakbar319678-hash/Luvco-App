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
  final bool isPublic;

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
    this.isPublic = true,
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
    bool? isPublic,
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
    isPublic: isPublic ?? this.isPublic,
  );

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final parsedDietTags = (json['dietTags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final parsedFreeOfTags = (json['freeOfTags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    return RecipeModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['coverImageUrl'] as String?,
      dietTags: parsedDietTags,
      timeOfPreparation: json['prepTimeMinutes'] as int? ?? 30,
      servings: json['servings'] as int? ?? 2,
      freeOfIngredients: parsedFreeOfTags,
      isSaved: json['isSaved'] as bool? ?? false,
      isPublic: json['isPublic'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverImageUrl': imageUrl,
      'dietTags': dietTags,
      'prepTimeMinutes': timeOfPreparation,
      'servings': servings,
      'freeOfTags': freeOfIngredients,
      'isSaved': isSaved,
      'isPublic': isPublic,
    };
  }
}
