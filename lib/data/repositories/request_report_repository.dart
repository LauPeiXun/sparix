import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparix/data/models/request_report.dart';

class RequestReportRepository {
  final CollectionReference _requestRef =
  FirebaseFirestore.instance.collection('part_request');

  Future<List<RequestReport>> getAllRequests() async {
    try {
      final snapshot = await _requestRef.get();
      return snapshot.docs
          .map((doc) => RequestReport.fromJson(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    } catch (e) {
      print("Error fetching all requests: $e");
      return [];
    }
  }

  Future<List<RequestReport>> getRequestsByDateRange(DateTime from, DateTime to) async {
    try {
      final snapshot = await _requestRef
          .where("orderDate", isGreaterThanOrEqualTo: from)
          .where("orderDate", isLessThanOrEqualTo: to)
          .get();

      return snapshot.docs
          .map((doc) => RequestReport.fromJson(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    } catch (e) {
      print("Error fetching requests by range: $e");
      return [];
    }
  }
}

