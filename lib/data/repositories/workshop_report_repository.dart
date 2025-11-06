import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparix/data/models/workshop_report.dart';
import 'package:sparix/data/models/spare_part.dart';

class WorkshopReportRepository {
  final CollectionReference _orderRef = FirebaseFirestore.instance.collection('order_list');
  final CollectionReference _productRef = FirebaseFirestore.instance.collection('spare_part');

  Future<List<ReportOrderList>> getAllOrderList() async {
    try {
      final snapshot = await _orderRef.get();
      return snapshot.docs
          .map((doc) => ReportOrderList.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching order_list: $e");
      return [];
    }
  }

  Future<Product?> getModelByProductID(String productId) async {
    try {
      final doc = await _productRef.doc(productId).get();
      if (doc.exists) {
        return Product.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error fetching spare_part by productId: $e");
      return null;
    }
  }
}
