// ── Product model ─────────────────────────────────────────────────
// Represents a single product that can be searched and added to a
// shopping list. The `sustainability` field drives the red/green badge.
class ProductModel {
  final String id;
  final String name;
  final String description;
  final String? imageAsset;       // large detail image (product_image.png)
  final String? thumbnailAsset;   // small list row thumbnail (nutila.png)
  final String? imageSvgAsset;    // SVG path (kept for reference)
  final bool isSustainable;       // true = "Safe" green, false = "Unsustainable" red
  final List<String> labels;
  final List<String> allergens;
  final List<String> ingredients;
  final bool isSaved;
  final String sustainabilityLabel;
  final String safetyLabel;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageAsset,
    this.thumbnailAsset,
    this.imageSvgAsset,
    this.isSustainable = true,
    this.labels = const [],
    this.allergens = const [],
    this.ingredients = const [],
    this.isSaved = false,
    this.sustainabilityLabel = 'Eco-Friendly',
    this.safetyLabel = 'Safe',
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageAsset,
    String? thumbnailAsset,
    String? imageSvgAsset,
    bool? isSustainable,
    List<String>? labels,
    List<String>? allergens,
    List<String>? ingredients,
    bool? isSaved,
    String? sustainabilityLabel,
    String? safetyLabel,
  }) => ProductModel(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    imageAsset: imageAsset ?? this.imageAsset,
    thumbnailAsset: thumbnailAsset ?? this.thumbnailAsset,
    imageSvgAsset: imageSvgAsset ?? this.imageSvgAsset,
    isSustainable: isSustainable ?? this.isSustainable,
    labels: labels ?? this.labels,
    allergens: allergens ?? this.allergens,
    ingredients: ingredients ?? this.ingredients,
    isSaved: isSaved ?? this.isSaved,
    sustainabilityLabel: sustainabilityLabel ?? this.sustainabilityLabel,
    safetyLabel: safetyLabel ?? this.safetyLabel,
  );

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final barcode = json['barcode'] as String? ?? json['id'] as String? ?? '';
    final name = json['name'] as String? ?? 'Unknown Product';
    final brand = json['brand'] as String? ?? 'Generic Brand';
    final imageUrl = json['imageUrl'] as String? ?? '';
    final sustainabilityLabelRaw = json['sustainabilityLabel'] as String? ?? '';
    
    // isSustainable: true if Eco-Friendly or Sustainable
    final isSustainable = sustainabilityLabelRaw.toLowerCase() == 'eco-friendly' ||
                          sustainabilityLabelRaw.toLowerCase() == 'sustainable' ||
                          sustainabilityLabelRaw.toLowerCase() == 'eco friendly';

    final labelsList = json['labels'] != null ? List<String>.from(json['labels']) : <String>[];
    final allergensList = json['allergens'] != null ? List<String>.from(json['allergens']) : <String>[];
    
    final ingredientsList = <String>[];
    if (json['ingredients'] != null && json['ingredients'] is List) {
      for (final ing in json['ingredients']) {
        if (ing is Map && ing['text'] != null) {
          ingredientsList.add(ing['text'] as String);
        } else if (ing is String) {
          ingredientsList.add(ing);
        }
      }
    }

    // Normalize sustainability level
    String sustainability = 'Moderate Impact';
    if (sustainabilityLabelRaw.isNotEmpty) {
      if (sustainabilityLabelRaw.toLowerCase().contains('unsustainable')) {
        sustainability = 'Unsustainable';
      } else if (sustainabilityLabelRaw.toLowerCase().contains('eco-friendly') ||
          sustainabilityLabelRaw.toLowerCase().contains('low') ||
          sustainabilityLabelRaw.toLowerCase().contains('sustainable') ||
          sustainabilityLabelRaw.toLowerCase().contains('eco friendly')) {
        sustainability = 'Eco-Friendly';
      }
    } else {
      sustainability = isSustainable ? 'Eco-Friendly' : 'Unsustainable';
    }

    // Normalize safety level
    String safety = 'Safe';
    final safetyLabelRaw = json['safetyLabel'] as String?;
    if (safetyLabelRaw != null && safetyLabelRaw.isNotEmpty) {
      if (safetyLabelRaw.toLowerCase().contains('avoid') ||
          safetyLabelRaw.toLowerCase().contains('high')) {
        safety = 'Avoid';
      }
    }

    return ProductModel(
      id: barcode,
      name: name,
      description: brand,
      imageAsset: imageUrl.isNotEmpty ? imageUrl : null,
      thumbnailAsset: imageUrl.isNotEmpty ? imageUrl : null,
      isSustainable: isSustainable,
      labels: labelsList,
      allergens: allergensList,
      ingredients: ingredientsList,
      isSaved: json['isFavorited'] as bool? ?? false,
      sustainabilityLabel: sustainability,
      safetyLabel: safety,
    );
  }

  /// Fallback demo product used when route extras are missing
  static ProductModel demo() => const ProductModel(
    id: 'demo_001',
    name: 'Name of the Product',
    description: 'Other data from the product.',
    imageAsset: 'assets/images/nutila.png',
    thumbnailAsset: 'assets/images/nutila.png',
    isSustainable: false,
    labels: ['Label', 'Label', 'Label', 'Label'],
    allergens: ['Label', 'Label', 'Label', 'Label'],
    ingredients: ['Ingredient Name', 'Ingredient Name', 'Ingredient Name'],
  );
}
