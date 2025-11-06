import 'package:flutter/foundation.dart';
import 'package:sparix/data/models/damage_report.dart';
import 'package:sparix/data/repositories/damage_report_repository.dart';
import 'package:sparix/data/repositories/product_repository.dart';
import 'dart:io';

class DamageReportProvider with ChangeNotifier {
  final DamageReportRepository _repository = DamageReportRepository();
  final ProductRepository _productRepository = ProductRepository();

  List<DamageReport> _damageReports = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<DamageReport> get damageReports => _damageReports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all damage reports
  Future<void> loadDamageReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _damageReports = await _repository.getAllDamageReports();
      // Sort by creation date (newest first)
      _damageReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString();
      _damageReports = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new damage report
  Future<bool> addDamageReport({
    required String partName,
    required String productId,
    required String reportType,
    required int quantity,
    required DateTime dateReported,
    required String reportedBy,
    String? description,
    required List<File> imageFiles,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Generate report ID
      final reportId = _repository.generateReportId();
      
      // Upload images and get URLs
      List<String> imageUrls = [];
      if (imageFiles.isNotEmpty) {
        imageUrls = await _repository.uploadReportImages(
          reportId: reportId,
          imageFiles: imageFiles,
        );
      }

      // Create damage report model
      final damageReport = DamageReport(
        reportId: reportId,
        partName: partName,
        productId: productId,
        reportType: reportType,
        quantity: quantity,
        dateReported: dateReported,
        reportedBy: reportedBy,
        description: description,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _repository.addDamageReport(damageReport);

      try {
        // Deduct quantity from product stock
        await _productRepository.deductProductStock(productId, quantity);
      } catch (stockError) {
        // If stock deduction fails, log the error but don't fail the entire operation
        // The report is already saved, we just couldn't update the stock
        if (kDebugMode) {
          print('Warning: Failed to deduct stock for product $productId: $stockError');
        }
      }

      // Add to local list and sort
      _damageReports.insert(0, damageReport);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update damage report
  Future<bool> updateDamageReport({
    required String reportId,
    String? partName,
    String? productId,
    String? reportType,
    int? quantity,
    DateTime? dateReported,
    String? reportedBy,
    String? description,
    List<File>? additionalImageFiles,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Find existing report
      final existingReportIndex = _damageReports.indexWhere(
        (report) => report.reportId == reportId,
      );
      
      if (existingReportIndex == -1) {
        throw Exception('Damage report not found');
      }

      final existingReport = _damageReports[existingReportIndex];
      List<String> imageUrls = List.from(existingReport.imageUrls);

      // Upload additional images if provided
      if (additionalImageFiles != null && additionalImageFiles.isNotEmpty) {
        final newImageUrls = await _repository.uploadReportImages(
          reportId: reportId,
          imageFiles: additionalImageFiles,
        );
        imageUrls.addAll(newImageUrls);
      }

      // Create updated report
      final updatedReport = existingReport.copyWith(
        partName: partName ?? existingReport.partName,
        productId: productId ?? existingReport.productId,
        reportType: reportType ?? existingReport.reportType,
        quantity: quantity ?? existingReport.quantity,
        dateReported: dateReported ?? existingReport.dateReported,
        reportedBy: reportedBy ?? existingReport.reportedBy,
        description: description ?? existingReport.description,
        imageUrls: imageUrls,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _repository.updateDamageReport(updatedReport);

      // Update local list
      _damageReports[existingReportIndex] = updatedReport;
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete damage report
  Future<bool> deleteDamageReport(String reportId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteDamageReport(reportId);
      
      // Remove from local list
      _damageReports.removeWhere((report) => report.reportId == reportId);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get damage reports by type
  Future<List<DamageReport>> getDamageReportsByType(String reportType) async {
    try {
      return await _repository.getDamageReportsByType(reportType);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get damage reports by product
  Future<List<DamageReport>> getDamageReportsByProduct(String productId) async {
    try {
      return await _repository.getDamageReportsByProduct(productId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get damage reports by date range
  Future<List<DamageReport>> getDamageReportsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _repository.getDamageReportsByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Search damage reports by part name
  Future<List<DamageReport>> searchDamageReports(String searchQuery) async {
    try {
      return await _repository.searchDamageReportsByPartName(searchQuery);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get damage reports stream for real-time updates
  Stream<List<DamageReport>> getDamageReportsStream() {
    return _repository.getAllDamageReportsStream();
  }

  // Get damage reports by type stream
  Stream<List<DamageReport>> getDamageReportsByTypeStream(String reportType) {
    return _repository.getDamageReportsByTypeStream(reportType);
  }

  // Filter local reports by type
  List<DamageReport> getFilteredReports(String? reportType) {
    if (reportType == null || reportType.isEmpty) {
      return _damageReports;
    }
    return _damageReports.where((report) => report.reportType == reportType).toList();
  }

  // Get report count by type
  int getReportCountByType(String reportType) {
    return _damageReports.where((report) => report.reportType == reportType).length;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadDamageReports();
  }
}