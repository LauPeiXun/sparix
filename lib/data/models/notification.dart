import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String notifId;
  final String title;
  final String body;
  final String? imageUrl;
  final String productId;
  final String productName;
  final int stock;
  final DateTime createdAt;
  bool read;

  Notification({
    required this.notifId,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.productId,
    required this.productName,
    required this.stock,
    required this.createdAt,
    this.read = false,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      notifId: json['notifId'] ?? '',
      title: json['title'] ?? '',
      imageUrl: (json['imageUrl'] as String?)?.trim().isEmpty == true
          ? null
          : json['imageUrl'],
      body: json['body'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      stock: json['stock'] ?? 0,
      createdAt: (json['createdAt'] is Timestamp)
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      read: json['read'] ?? false,
    );
  }

  get timestamp => null;

  Map<String, dynamic> toJson() {
    return {
      'notifId': notifId,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'productId': productId,
      'productName': productName,
      'stock': stock,
      'createdAt': createdAt,
      'read': read,
    };
  }
}
