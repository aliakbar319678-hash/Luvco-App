class RecipeModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String ownerName; // Full name of the recipe creator
  final List<String> dietTags;
  final int timeOfPreparation; // minutes
  final int servings;
  final List<String> freeOfIngredients;
  final bool isSaved;
  final bool isPublic;
  final DateTime? createdAt;
  final int saveCount;

  const RecipeModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.ownerName = '',
    this.dietTags = const [],
    this.timeOfPreparation = 30,
    this.servings = 2,
    this.freeOfIngredients = const [],
    this.isSaved = false,
    this.isPublic = true,
    this.createdAt,
    this.saveCount = 0,
  });

  RecipeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? ownerName,
    List<String>? dietTags,
    int? timeOfPreparation,
    int? servings,
    List<String>? freeOfIngredients,
    bool? isSaved,
    bool? isPublic,
    DateTime? createdAt,
    int? saveCount,
  }) => RecipeModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    ownerName: ownerName ?? this.ownerName,
    dietTags: dietTags ?? this.dietTags,
    timeOfPreparation: timeOfPreparation ?? this.timeOfPreparation,
    servings: servings ?? this.servings,
    freeOfIngredients: freeOfIngredients ?? this.freeOfIngredients,
    isSaved: isSaved ?? this.isSaved,
    isPublic: isPublic ?? this.isPublic,
    createdAt: createdAt ?? this.createdAt,
    saveCount: saveCount ?? this.saveCount,
  );

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final parsedDietTags = (json['dietTags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final parsedFreeOfTags = (json['freeOfTags'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    // Parse owner name directly or from nested owner object
    String ownerName = json['ownerName'] as String? ?? '';
    if (ownerName.isEmpty) {
      final ownerJson = json['owner'] as Map<String, dynamic>?;
      if (ownerJson != null) {
        final first = ownerJson['firstName'] as String? ?? '';
        final last = ownerJson['lastName'] as String? ?? '';
        ownerName = '$first $last'.trim();
      }
    }

    return RecipeModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['coverImageUrl'] as String?,
      ownerName: ownerName,
      dietTags: parsedDietTags,
      timeOfPreparation: json['prepTimeMinutes'] as int? ?? 30,
      servings: json['servings'] as int? ?? 2,
      freeOfIngredients: parsedFreeOfTags,
      isSaved: json['isSaved'] as bool? ?? false,
      isPublic: json['isPublic'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      saveCount: json['saveCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverImageUrl': imageUrl,
      'ownerName': ownerName,
      'dietTags': dietTags,
      'prepTimeMinutes': timeOfPreparation,
      'servings': servings,
      'freeOfTags': freeOfIngredients,
      'isSaved': isSaved,
      'isPublic': isPublic,
      'createdAt': createdAt?.toIso8601String(),
      'saveCount': saveCount,
    };
  }
}
