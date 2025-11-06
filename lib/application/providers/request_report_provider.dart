import 'package:flutter/material.dart';
import 'package:sparix/data/models/request_report.dart';
import 'package:sparix/data/repositories/request_report_repository.dart';

class RequestReportProvider extends ChangeNotifier {
  final RequestReportRepository _repository = RequestReportRepository();

  List<RequestReport> _reports = [];
  bool _isLoading = false;

  List<RequestReport> get reports => _reports;
  bool get isLoading => _isLoading;

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      _reports = await _repository.getAllRequests();
    } catch (e) {
      debugPrint("Error loading reports: $e");
      _reports = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshReports() async {
    await loadReports();
  }
}
