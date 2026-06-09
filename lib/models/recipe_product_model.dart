class RecipeProductModel {
  final String id;
  final String recipeId;
  final String? barcode;
  final String productName;
  final String productImageUrl;
  final int quantity;
  final String? unit;
  final int position;
  final String sustainabilityLevel;
  final String safetyLevel;

  const RecipeProductModel({
    required this.id,
    required this.recipeId,
    this.barcode,
    required this.productName,
    required this.productImageUrl,
    required this.quantity,
    this.unit,
    required this.position,
    required this.sustainabilityLevel,
    required this.safetyLevel,
  });

  // Compatibility getters for existing UI
  String get name => productName;
  String get otherData => '$quantity ${unit ?? ''}'.trim();
  String? get imageAsset => productImageUrl.isEmpty ? null : productImageUrl;

  factory RecipeProductModel.fromJson(Map<String, dynamic> json) {
    final details = json['productDetails'] as Map<String, dynamic>?;

    // Normalize sustainability level
    String sustainability = 'Moderate Impact';
    final backendSust = details?['sustainabilityLevel'] as String?;
    if (backendSust != null) {
      if (backendSust.toLowerCase().contains('unsustainable')) {
        sustainability = 'Unsustainable';
      } else if (backendSust.toLowerCase().contains('eco-friendly') || backendSust.toLowerCase().contains('low')) {
        sustainability = 'Eco-Friendly';
      }
    }

    // Normalize safety level
    String safety = 'Safe';
    final backendSafety = details?['safetyLevel'] as String?;
    if (backendSafety != null) {
      if (backendSafety.toLowerCase().contains('avoid') || backendSafety.toLowerCase().contains('high')) {
        safety = 'Avoid';
      }
    }

    return RecipeProductModel(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      barcode: json['barcode'] as String?,
      productName: json['productName'] as String? ?? '',
      productImageUrl: json['productImageUrl'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit'] as String?,
      position: json['position'] as int? ?? 1,
      sustainabilityLevel: sustainability,
      safetyLevel: safety,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'barcode': barcode,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'quantity': quantity,
      'unit': unit,
      'position': position,
    };
  }
}
