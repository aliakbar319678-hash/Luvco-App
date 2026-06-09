class RecipeIngredientModel {
  final String id;
  final String recipeId;
  final String description;
  final int position;

  const RecipeIngredientModel({
    required this.id,
    required this.recipeId,
    required this.description,
    required this.position,
  });

  factory RecipeIngredientModel.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientModel(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      description: json['description'] as String? ?? '',
      position: json['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'description': description,
      'position': position,
    };
  }
}
