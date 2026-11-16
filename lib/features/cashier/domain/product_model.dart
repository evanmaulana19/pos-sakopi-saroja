class Product {
  final int id;
  final int categoryId;
  final String name;
  final double price;
  final String imageUrl;
  final bool isAvailable;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      isAvailable: json['is_available'] as bool,
    );
  }

  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    double? price,
    String? imageUrl,
    bool? isAvailable,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
