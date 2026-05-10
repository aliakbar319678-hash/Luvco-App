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
  );
}
