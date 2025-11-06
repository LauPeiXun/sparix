import 'package:cloud_firestore/cloud_firestore.dart';

class Supplier {
  final String id;
  final String supplierName;
  final int contact;
  final String supplierID;

  Supplier({
    required this.id,
    required this.supplierName,
    required this.contact,
    required this.supplierID,
  });

  factory Supplier.fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? const {};
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v == null) return 0;
      return int.tryParse(v.toString()) ?? 0;
    }

    return Supplier(
      id: snap.id,
      supplierName: (d['name'] ?? '').toString(),
      contact: asInt(d['contact']),
      supplierID: (d['supplierID'] ?? '').toString(),
    );
  }
}
