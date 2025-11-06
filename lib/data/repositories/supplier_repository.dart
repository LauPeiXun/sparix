import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier.dart';

class SupplierRepository {
  final _db = FirebaseFirestore.instance;

  Future<Supplier?> getById(String id) async {
    final tid = id.trim();
    if (tid.isEmpty) return null;
    final snap = await _db.collection('supplier').doc(tid).get();
    if (!snap.exists) return null;
    return Supplier.fromSnap(snap);
  }

  Stream<Supplier?> watchById(String id) {
    final tid = id.trim();
    if (tid.isEmpty) return const Stream.empty();
    return _db.collection('supplier').doc(tid).snapshots().map((s) {
      if (!s.exists) return null;
      return Supplier.fromSnap(s);
    });
  }
}
