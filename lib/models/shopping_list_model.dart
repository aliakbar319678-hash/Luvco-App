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

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['itemCount'] != null) {
      count = json['itemCount'] as int;
    } else if (json['items'] != null && json['items'] is List) {
      count = (json['items'] as List).length;
    }

    final desc = json['description'] as String? ?? 'Custom shopping list';

    String? imgUrl = json['imageUrl'] as String?;
    if (imgUrl == null && json['items'] != null && json['items'] is List) {
      final list = json['items'] as List;
      if (list.isNotEmpty) {
        final firstItem = list[0];
        if (firstItem is Map<String, dynamic>) {
          imgUrl = firstItem['productImageUrl'] as String?;
        }
      }
    }

    return ShoppingListModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Shopping List',
      description: desc,
      itemCount: count,
      imageUrl: imgUrl ?? 'assets/images/bread_pic.png',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'itemCount': itemCount,
      'imageUrl': imageUrl,
    };
  }
}
