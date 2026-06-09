class RecipeInstructionModel {
  final String id;
  final String recipeId;
  final int stepNumber;
  final String text;

  const RecipeInstructionModel({
    required this.id,
    required this.recipeId,
    required this.stepNumber,
    required this.text,
  });

  factory RecipeInstructionModel.fromJson(Map<String, dynamic> json) {
    return RecipeInstructionModel(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      stepNumber: json['stepNumber'] as int? ?? 1,
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'stepNumber': stepNumber,
      'text': text,
    };
  }
}
