import 'package:cloud_firestore/cloud_firestore.dart';

class RequestReport {
  final String id;          // Firestore docId
  final String requestId;   // e.g. "SPR000001"
  final String requestType; // e.g. "Work Order"
  final String status;      // e.g. "approved"
  final String statusColor; // e.g. "#4CAF50"
  final String workshopId;
  final String remark;
  final DateTime orderDate;
  final DateTime updatedAt;
  final List<RequestItem> itemList;

  RequestReport({
    required this.id,
    required this.requestId,
    required this.requestType,
    required this.status,
    required this.statusColor,
    required this.workshopId,
    required this.remark,
    required this.orderDate,
    required this.updatedAt,
    required this.itemList,
  });


  DateTime get createdAt => orderDate;
  String get partName => requestType;


  static DateTime _toDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }


  factory RequestReport.fromJson(Map<String, dynamic> json, {String? docId}) {
    return RequestReport(
      id: docId ?? '', // Firestore docId
      requestId: json['requestId'] ?? '',
      requestType: json['requestType'] ?? '',
      status: json['status'] ?? '',
      statusColor: json['statusColor'] ?? '',
      workshopId: json['workshopId'] ?? '',
      remark: json['remark'] ?? '',
      orderDate: _toDate(json['orderDate']),
      updatedAt: _toDate(json['updatedAt']),
      itemList: (json['itemList'] as List<dynamic>? ?? [])
          .map((e) => RequestItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'requestType': requestType,
      'status': status,
      'statusColor': statusColor,
      'workshopId': workshopId,
      'remark': remark,
      'orderDate': Timestamp.fromDate(orderDate),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'itemList': itemList.map((e) => e.toJson()).toList(),
    };
  }
}

class RequestItem {
  final String itemDocId;
  final int quantity;

  RequestItem({
    required this.itemDocId,
    required this.quantity,
  });


  factory RequestItem.fromJson(Map<String, dynamic> json) {
    final itemData = json['item'] as Map<String, dynamic>? ?? {};
    return RequestItem(
      itemDocId: itemData['itemDocId'] ?? '',
      quantity: (itemData['quantity'] ?? 0) as int,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'item': {
        'itemDocId': itemDocId,
        'quantity': quantity,
      }
    };
  }
}
