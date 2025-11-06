import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_item.dart';

class ReportOrderList {
  final String code;
  final String status;
  final DateTime date;
  final int itemCount;
  final List<OrderItem> items;
  final String supplier;
  final double totalAmount;
  final DateTime updatedAt;

  ReportOrderList({
    required this.code,
    required this.status,
    required this.date,
    required this.itemCount,
    required this.items,
    required this.supplier,
    required this.totalAmount,
    required this.updatedAt,
  });

  static DateTime _toDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  factory ReportOrderList.fromJson(Map<String, dynamic> json) {
    return ReportOrderList(
      code: json['orderID'] ?? '',
      status: json['status'] ?? 'pending',
      date: _toDate(json['date']),
      itemCount: (json['itemCount'] ?? 0) as int,
      supplier: json['supplier'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      updatedAt: _toDate(json['updatedAt']),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'status': status,
      'date': date.toIso8601String(),
      'itemCount': itemCount,
      'supplier': supplier,
      'totalAmount': totalAmount,
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
