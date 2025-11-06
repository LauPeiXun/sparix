import 'package:cloud_firestore/cloud_firestore.dart';

class DamageReport {
  final String reportId;
  final String partName;
  final String productId;
  final String reportType; // 'Damage', 'Request', 'Lost'
  final int quantity;
  final DateTime dateReported;
  final String reportedBy;
  final String? description;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DamageReport({
    required this.reportId,
    required this.partName,
    required this.productId,
    required this.reportType,
    required this.quantity,
    required this.dateReported,
    required this.reportedBy,
    this.description,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create from JSON
  factory DamageReport.fromJson(Map<String, dynamic> json) {
    return DamageReport(
      reportId: json['reportId'] ?? '',
      partName: json['partName'] ?? '',
      productId: json['productId'] ?? '',
      reportType: json['reportType'] ?? '',
      quantity: json['quantity'] ?? 0,
      dateReported: json['dateReported'] is Timestamp
          ? (json['dateReported'] as Timestamp).toDate()
          : DateTime.parse(json['dateReported']),
      reportedBy: json['reportedBy'] ?? '',
      description: json['description'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt']),
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'partName': partName,
      'productId': productId,
      'reportType': reportType,
      'quantity': quantity,
      'dateReported': Timestamp.fromDate(dateReported),
      'reportedBy': reportedBy,
      'description': description,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method for creating modified copies
  DamageReport copyWith({
    String? reportId,
    String? partName,
    String? productId,
    String? reportType,
    int? quantity,
    DateTime? dateReported,
    String? reportedBy,
    String? description,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DamageReport(
      reportId: reportId ?? this.reportId,
      partName: partName ?? this.partName,
      productId: productId ?? this.productId,
      reportType: reportType ?? this.reportType,
      quantity: quantity ?? this.quantity,
      dateReported: dateReported ?? this.dateReported,
      reportedBy: reportedBy ?? this.reportedBy,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DamageReport &&
        other.reportId == reportId &&
        other.partName == partName &&
        other.productId == productId &&
        other.reportType == reportType &&
        other.quantity == quantity &&
        other.dateReported == dateReported &&
        other.reportedBy == reportedBy &&
        other.description == description &&
        _listEquals(other.imageUrls, imageUrls) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      reportId,
      partName,
      productId,
      reportType,
      quantity,
      dateReported,
      reportedBy,
      description,
      imageUrls,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'DamageReport{reportId: $reportId, partName: $partName, reportType: $reportType, quantity: $quantity, dateReported: $dateReported, reportedBy: $reportedBy}';
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}