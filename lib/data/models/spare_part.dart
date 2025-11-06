class Product {
  final String productId;
  final String name;
  final double price;
  final double salesAmount;
  final String currency;
  final int stock;
  final int stockThreshold;
  final String status;
  final String warehouse;
  final String rack;
  final String section;
  final String brand;
  final String model;
  final String category;
  final String position;
  final int warrantyMonths;
  final String imageUrl;
  final List<String> description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.productId,
    required this.name,
    required this.price,
    required this.salesAmount,
    required this.currency,
    required this.stock,
    required this.stockThreshold,
    required this.status,
    required this.warehouse,
    required this.rack,
    required this.section,
    required this.brand,
    required this.model,
    required this.category,
    required this.position,
    required this.warrantyMonths,
    this.imageUrl = '',
    this.description = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      price: (json['price']).toDouble(),
      salesAmount: (json['salesAmount']).toDouble(),
      currency: json['currency'] ?? '',
      stock: json['stock'] ?? 0,
      stockThreshold: json['stockThreshold'] ?? 5,
      status: json['status'] ?? '',
      warehouse: json['warehouse'] ?? '',
      rack: json['rack'] ?? '',
      section: json['section'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      category: json['category'] ?? '',
      position: json['position'] ?? '',
      warrantyMonths: json['warrantyMonths'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      description: List<String>.from(json['description'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'salesAmount': salesAmount,
      'currency': currency,
      'stock': stock,
      'stockThreshold': stockThreshold,
      'status': status,
      'warehouse': warehouse,
      'rack': rack,
      'section': section,
      'brand': brand,
      'model': model,
      'category': category,
      'position': position,
      'warrantyMonths': warrantyMonths,
      'imageUrl': imageUrl,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? productId,
    String? name,
    double? price,
    double? salesAmount,
    String? currency,
    int? stock,
    int? stockThreshold,
    String? status,
    String? warehouse,
    String? rack,
    String? section,
    String? brand,
    String? model,
    String? category,
    String? position,
    int? warrantyMonths,
    String? imageUrl,
    List<String>? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      salesAmount: salesAmount ?? this.salesAmount,
      currency: currency ?? this.currency,
      stock: stock ?? this.stock,
      stockThreshold: stockThreshold ?? this.stockThreshold,
      status: status ?? this.status,
      warehouse: warehouse ?? this.warehouse,
      rack: rack ?? this.rack,
      section: section ?? this.section,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      category: category ?? this.category,
      position: position ?? this.position,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.productId == productId &&
        other.name == name &&
        other.price == price &&
        other.stock == stock;
  }

  @override
  int get hashCode =>
      productId.hashCode ^ name.hashCode ^ price.hashCode ^ stock.hashCode;

  @override
  String toString() {
    return 'Product(productId: $productId, name: $name, price: $price, stock: $stock)';
  }
}
