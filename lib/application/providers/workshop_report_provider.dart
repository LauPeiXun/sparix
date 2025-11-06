import 'package:flutter/material.dart';
import 'package:sparix/data/models/workshop_report.dart';
import 'package:sparix/data/models/spare_part.dart';
import 'package:sparix/data/repositories/workshop_report_repository.dart';

class WorkshopReportProvider extends ChangeNotifier {
  final WorkshopReportRepository _repository = WorkshopReportRepository();

  List<ReportOrderList> _orders = [];
  List<ReportOrderList> get orders => _orders;

  final Map<String, Product?> _products = {};
  Map<String, Product?> get products => _products;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAllOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _repository.getAllOrderList();
      final ids = _orders.expand((o) => o.items.map((i) => i.productId)).toSet();

      for (final id in ids) {
        if (!_products.containsKey(id)) {
          final product = await _repository.getModelByProductID(id);
          if (product != null) {
            _products[id] = product;
            debugPrint("Loaded productId=$id, model=${product.model}");
          } else {
            debugPrint("Product not found for id=$id");
          }
        }
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Failed to fetch orders: $e";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Product?> fetchProductById(String productId) async {
    if (_products.containsKey(productId)) {
      return _products[productId];
    }
    try {
      final product = await _repository.getModelByProductID(productId);
      _products[productId] = product;
      notifyListeners();
      return product;
    } catch (e) {
      print("Failed to fetch product $productId: $e");
      _products[productId] = null;
      notifyListeners();
      return null;
    }
  }
}
