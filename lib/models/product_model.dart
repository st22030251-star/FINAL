class Product {
  final String id;
  final String name;
  final double price;
  final String sku;
  final String category;
  final int stock;
  final bool isPrivate;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.sku,
    required this.category,
    required this.stock,
    this.isPrivate = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'sku': sku,
      'category': category,
      'stock': stock,
      'isPrivate': isPrivate,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      sku: map['sku'] ?? '',
      category: map['category'] ?? '',
      stock: map['stock'] ?? 0,
      isPrivate: map['isPrivate'] ?? false,
    );
  }
}
