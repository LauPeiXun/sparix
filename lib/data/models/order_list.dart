import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemRaw {
  final String productId; // 兼容 productID / productId
  final int orderedQty;   // 兼容 orderedQty / orderQty
  final int goodQty;
  final int damageQty;

  OrderItemRaw({
    required this.productId,
    required this.orderedQty,
    required this.goodQty,
    required this.damageQty,
  });

  factory OrderItemRaw.fromMap(Map<String, dynamic> m) {
    String asString(dynamic v) => v == null ? '' : v.toString();
    int asInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(asString(v)) ?? 0;
    }

    return OrderItemRaw(
      productId: asString(m['productID'] ?? m['productId']),
      orderedQty: asInt(m['orderedQty'] ?? m['orderQty']),
      goodQty: asInt(m['goodQty']),
      damageQty: asInt(m['damageQty']),
    );
  }

  Map<String, dynamic> toMap() => {
    'productID': productId,
    'orderedQty': orderedQty,
    'goodQty': goodQty,
    'damageQty': damageQty,
  };
}

class OrderDoc {
  final String id;          // docId
  final String orderCode;   // orderID (显示用编号，如 CM9801)
  final String status;      // pending/completed/returned
  final String supplierId;  // supplier 文档 id（字段名叫 supplier）
  final DateTime orderDate;
  final double? totalAmount;
  final int itemCount;
  final List<OrderItemRaw> items;

  OrderDoc({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.supplierId,
    required this.orderDate,
    required this.items,
    required this.itemCount,
    this.totalAmount,
  });

  factory OrderDoc.fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? const {};
    String asString(dynamic v) => v == null ? '' : v.toString();
    int asInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(asString(v)) ?? 0;
    }
    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(asString(v)) ?? 0;
    }

    final rawItems = (d['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItemRaw.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return OrderDoc(
      id: snap.id,
      orderCode: asString(d['orderID'].toString().isEmpty ? snap.id : d['orderID']),
      status: asString(d['status']),
      supplierId: asString(d['supplier']),
      orderDate: (d['orderDate'] as Timestamp).toDate(),
      totalAmount: d['totalAmount'] == null ? null : asDouble(d['totalAmount']),
      itemCount: (d['itemCount'] == null) ? rawItems.length : asInt(d['itemCount']),
      items: rawItems,
    );
  }
}
