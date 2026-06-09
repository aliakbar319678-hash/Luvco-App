import 'recipe_model.dart';
import 'recipe_ingredient_model.dart';
import 'recipe_instruction_model.dart';
import 'recipe_product_model.dart';

typedef RecipeProduct = RecipeProductModel;

class RecipeDetailModel {
  final RecipeModel core;
  final List<RecipeIngredientModel> ingredientsList;
  final List<RecipeInstructionModel> instructionsList;
  final List<RecipeProductModel> products;
  final bool isOwner;

  const RecipeDetailModel({
    required this.core,
    this.ingredientsList = const [],
    this.instructionsList = const [],
    this.products = const [],
    this.isOwner = false,
  });

  // Compatibility getters for existing UI code
  String get id => core.id;
  String get title => core.title;
  String get description => core.description;
  String? get imageUrl => core.imageUrl;
  int get servings => core.servings;
  int get timeMinutes => core.timeOfPreparation;
  List<String> get dietTypes => core.dietTags;
  List<String> get freeOfIngredients => core.freeOfIngredients;
  bool get isSaved => core.isSaved;

  String get ingredients {
    return ingredientsList.map((e) => '• ${e.description}').join('\n');
  }

  String get instructions {
    final sorted = List<RecipeInstructionModel>.from(instructionsList)
      ..sort((a, b) => a.stepNumber.compareTo(b.stepNumber));
    return sorted.map((e) => '${e.stepNumber}. ${e.text}').join('\n\n');
  }

  RecipeDetailModel copyWith({
    RecipeModel? core,
    List<RecipeIngredientModel>? ingredientsList,
    List<RecipeInstructionModel>? instructionsList,
    List<RecipeProductModel>? products,
    bool? isOwner,
  }) =>
      RecipeDetailModel(
        core: core ?? this.core,
        ingredientsList: ingredientsList ?? this.ingredientsList,
        instructionsList: instructionsList ?? this.instructionsList,
        products: products ?? this.products,
        isOwner: isOwner ?? this.isOwner,
      );

  factory RecipeDetailModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final recipeJson = json['recipe'] as Map<String, dynamic>? ?? json;
    final recipe = RecipeModel.fromJson(recipeJson);
    
    final ingList = (json['ingredients'] as List?)
        ?.map((e) => RecipeIngredientModel.fromJson(e as Map<String, dynamic>))
        .toList() ??
        const <RecipeIngredientModel>[];
        
    final instList = (json['instructions'] as List?)
        ?.map((e) => RecipeInstructionModel.fromJson(e as Map<String, dynamic>))
        .toList() ??
        const <RecipeInstructionModel>[];
        
    final prodList = (json['products'] as List?)
        ?.map((e) => RecipeProductModel.fromJson(e as Map<String, dynamic>))
        .toList() ??
        const <RecipeProductModel>[];

    final ownerId = recipeJson['ownerId'] as String?;
    final isOwner = ownerId != null && ownerId == currentUserId;

    return RecipeDetailModel(
      core: recipe,
      ingredientsList: ingList,
      instructionsList: instList,
      products: prodList,
      isOwner: isOwner,
    );
  }
}
