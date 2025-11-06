import 'package:cloud_firestore/cloud_firestore.dart';

class SparePart {
  final String id;
  final String name;
  final double price;
  final double salesAmount;
  final String imageUrl;
  final String brand;
  final String model;
  final String category;

  SparePart({
    required this.id,
    required this.name,
    required this.price,
    required this.salesAmount,
    required this.imageUrl,
    required this.brand,
    required this.model,
    required this.category,
  });

  factory SparePart.fromMap(String id, Map<String, dynamic> data) {
    return SparePart(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      salesAmount: (data['salesAmount'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      category: data['category'] ?? '',
    );
  }
}


class PartRequestItem {
  final String itemDocId;
  final int quantity;

  PartRequestItem({
    required this.itemDocId,
    required this.quantity,
  });

  factory PartRequestItem.fromMap(Map<String, dynamic> data) {
    final itemData = data['item'] ?? data;
    return PartRequestItem(
      itemDocId: (itemData['itemDocId'] ?? '') as String,
      quantity: (itemData['quantity'] ?? 0).toInt(),
    );
  }
}

class PartRequest {
  final String id;
  final List<PartRequestItem> itemList;
  final DateTime orderDate;
  final String requestId;
  final String status;

  PartRequest({
    required this.id,
    required this.itemList,
    required this.orderDate,
    required this.requestId,
    required this.status,
  });

  factory PartRequest.fromMap(String id, Map<String, dynamic> data) {

    final raw = data['itemList'] ?? data['itemLIst'] ?? data['item'] ?? [];

    List<PartRequestItem> items = [];
    if (raw is List) {
      items = raw.map((e) => PartRequestItem.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } else if (raw is Map) {
      items = [PartRequestItem.fromMap(Map<String, dynamic>.from(raw))];
    } else {
      items = [];
    }


    final od = data['orderDate'];
    DateTime orderDate;
    if (od is Timestamp) {
      orderDate = od.toDate();
    } else if (od is DateTime) {
      orderDate = od;
    } else if (od is String) {
      orderDate = DateTime.tryParse(od) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      orderDate = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return PartRequest(
      id: id,
      itemList: items,
      orderDate: orderDate,
      requestId: data['requestId'] ?? '',
      status: data['status'] ?? '',
    );
  }
}
