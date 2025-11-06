import 'package:sparix/core/services/firebase_firestore_service.dart';
import 'package:sparix/core/services/firebase_storage_service.dart';
import 'package:sparix/data/models/damage_report.dart';
import 'dart:io';

class DamageReportRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  static const String collectionName = 'damage_reports';

  /// Generate new report ID
  String generateReportId() {
    return _firestoreService.generateDocId(collectionName);
  }

  /// Add damage report to Firestore
  Future<void> addDamageReport(DamageReport report) async {
    try {
      await _firestoreService.setModel<DamageReport>(
        collection: collectionName,
        docId: report.reportId,
        model: report,
        toMap: (model) => model.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Upload multiple report images and get URLs
  Future<List<String>> uploadReportImages({
    required String reportId,
    required List<File> imageFiles,
  }) async {
    try {
      List<String> imageUrls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final fileName = '${reportId}_image_$i.jpg';
        
        // Upload image to Firebase Storage
        await _storageService.uploadImage(
          'damage_report_images',
          fileName,
          imageFiles[i],
        );

        // Get download URL
        final imageUrl = await _storageService.getImage(
          'damage_report_images',
          fileName,
        );

        if (imageUrl != null && imageUrl.isNotEmpty) {
          imageUrls.add(imageUrl);
        }
      }

      return imageUrls;
    } catch (e) {
      rethrow;
    }
  }

  /// Get damage report by ID
  Future<DamageReport?> getDamageReportById(String reportId) async {
    try {
      return await _firestoreService.getModel<DamageReport>(
        collection: collectionName,
        docId: reportId,
        fromMap: (map) {
          final enrichedMap = {
            'reportId': reportId,
            ...map,
          };
          return DamageReport.fromJson(enrichedMap);
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get all damage reports
  Future<List<DamageReport>> getAllDamageReports() async {
    try {
      final snapshot = await _firestoreService.getCollection(collectionName);
      return snapshot.docs.map((doc) {
        return DamageReport.fromJson({
          'reportId': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get damage reports by report type
  Future<List<DamageReport>> getDamageReportsByType(String reportType) async {
    try {
      final snapshot = await _firestoreService.getCollection(collectionName);
      final allReports = snapshot.docs.map((doc) {
        return DamageReport.fromJson({
          'reportId': doc.id,
          ...doc.data(),
        });
      }).toList();
      
      // Filter by report type
      return allReports.where((report) => report.reportType == reportType).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get damage reports by product ID
  Future<List<DamageReport>> getDamageReportsByProduct(String productId) async {
    try {
      final snapshot = await _firestoreService.getCollection(collectionName);
      final allReports = snapshot.docs.map((doc) {
        return DamageReport.fromJson({
          'reportId': doc.id,
          ...doc.data(),
        });
      }).toList();
      
      // Filter by product ID
      return allReports.where((report) => report.productId == productId).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get damage reports by date range
  Future<List<DamageReport>> getDamageReportsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestoreService.getCollection(collectionName);
      final allReports = snapshot.docs.map((doc) {
        return DamageReport.fromJson({
          'reportId': doc.id,
          ...doc.data(),
        });
      }).toList();
      
      // Filter by date range and sort
      final filteredReports = allReports.where((report) {
        return report.dateReported.isAfter(startDate.subtract(const Duration(days: 1))) &&
               report.dateReported.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
      
      // Sort by date (newest first)
      filteredReports.sort((a, b) => b.dateReported.compareTo(a.dateReported));
      
      return filteredReports;
    } catch (e) {
      rethrow;
    }
  }

  /// Update damage report
  Future<void> updateDamageReport(DamageReport report) async {
    try {
      await _firestoreService.updateDocument(
        collection: collectionName,
        docId: report.reportId,
        data: report.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete damage report
  Future<void> deleteDamageReport(String reportId) async {
    try {
      await _firestoreService.deleteDocument(
        collection: collectionName,
        docId: reportId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Check if damage report exists
  Future<bool> damageReportExists(String reportId) async {
    try {
      final doc = await _firestoreService.getDocument(
        collection: collectionName,
        docId: reportId,
      );
      return doc.exists;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all damage reports as a stream for real-time updates
  Stream<List<DamageReport>> getAllDamageReportsStream() {
    return _firestoreService.streamCollection(collection: collectionName)
        .map((snapshot) => snapshot.docs.map((doc) {
          return DamageReport.fromJson({
            'reportId': doc.id,
            ...doc.data(),
          });
        }).toList());
  }

  /// Get damage reports by type as a stream
  Stream<List<DamageReport>> getDamageReportsByTypeStream(String reportType) {
    return _firestoreService.streamCollection(
      collection: collectionName,
      queryBuilder: (query) => query
          .where('reportType', isEqualTo: reportType)
          .orderBy('createdAt', descending: true),
    ).map((snapshot) => snapshot.docs.map((doc) {
          return DamageReport.fromJson({
            'reportId': doc.id,
            ...doc.data(),
          });
        }).toList());
  }

  /// Search damage reports by part name
  Future<List<DamageReport>> searchDamageReportsByPartName(String searchQuery) async {
    try {
      final snapshot = await _firestoreService.getCollection(collectionName);
      final allReports = snapshot.docs.map((doc) {
        return DamageReport.fromJson({
          'reportId': doc.id,
          ...doc.data(),
        });
      }).toList();

      // Filter reports by part name (case insensitive)
      final searchLower = searchQuery.toLowerCase();
      final filteredReports = allReports.where((report) {
        return report.partName.toLowerCase().contains(searchLower);
      }).toList();

      // Sort by date (newest first)
      filteredReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return filteredReports;
    } catch (e) {
      rethrow;
    }
  }
}