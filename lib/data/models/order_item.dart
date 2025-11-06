class OrderItem {
  final String productId;
  final int orderedQty;
  final int goodQty;
  final int damageQty;

  OrderItem({
    required this.productId,
    required this.orderedQty,
    required this.goodQty,
    required this.damageQty,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productID'] ?? '',
      orderedQty: (json['orderedQty'] ?? json['orderQty'] ?? 0) as int,
      goodQty: (json['goodQty'] ?? 0) as int,
      damageQty: (json['damageQty'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productID': productId,
      'orderedQty': orderedQty,
      'goodQty': goodQty,
      'damageQty': damageQty,
    };
  }
}
