import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sales_report.dart';

class SalesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<PartRequest>> fetchPartRequests(DateTime from,
      DateTime to) async {
    final query = await _firestore
        .collection('part_request')
        .where('orderDate', isGreaterThanOrEqualTo: from)
        .where('orderDate', isLessThanOrEqualTo: to)
        .get();

    return query.docs
        .map((doc) => PartRequest.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<SparePart?> fetchSparePart(String id) async {
    final doc = await _firestore.collection('spare_part').doc(id).get();
    if (doc.exists) {
      return SparePart.fromMap(doc.id, doc.data()!);
    }
    return null;
  }
}
