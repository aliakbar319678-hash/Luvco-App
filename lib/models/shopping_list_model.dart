class ShoppingListModel {
  final String id;
  final String title;
  final String description;
  final int itemCount;
  final String? imageUrl; // local asset or network

  const ShoppingListModel({
    required this.id,
    required this.title,
    required this.description,
    required this.itemCount,
    this.imageUrl,
  });


  ShoppingListModel copyWith({
    String? id,
    String? title,
    String? description,
    int? itemCount,
    String? imageUrl,
  }) => ShoppingListModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    itemCount: itemCount ?? this.itemCount,
    imageUrl: imageUrl ?? this.imageUrl,
  );
}
