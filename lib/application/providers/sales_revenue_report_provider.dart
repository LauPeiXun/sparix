import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sparix/data/models/sales_report.dart';
import 'package:sparix/data/repositories/salesrevenue_report_repository.dart';

class SalesRevenueProvider extends ChangeNotifier {
  final SalesRepository _repository = SalesRepository();

  List<PartRequest> _requests = [];       // 🔹 Filtered by date range
  List<PartRequest> _yearlyRequests = []; // 🔹 Always full-year requests
  Map<String, SparePart> _spareParts = {};
  bool _isLoading = false;

  DateTime? from;
  DateTime? to;

  List<PartRequest> get requests => _requests;
  Map<String, SparePart> get spareParts => _spareParts;
  bool get isLoading => _isLoading;

  // ----------------- LINE CHART -----------------
  List<FlSpot> get salesSpots {
    if (_requests.isEmpty || _spareParts.isEmpty) return [];

    final Map<DateTime, double> dailyTotals = {};

    for (var r in _requests) {
      final day = DateTime(r.orderDate.year, r.orderDate.month, r.orderDate.day);

      final totalSales = r.itemList.fold<double>(0, (sum, item) {
        final sp = _spareParts[item.itemDocId];
        if (sp != null) {
          return sum + sp.salesAmount * item.quantity;
        }
        return sum;
      });

      dailyTotals[day] = (dailyTotals[day] ?? 0) + totalSales;
    }

    final sortedDays = dailyTotals.keys.toList()..sort();

    return List.generate(sortedDays.length, (i) {
      final day = sortedDays[i];
      return FlSpot(i.toDouble(), dailyTotals[day]!);
    });
  }

  double get minX => 0;
  double get maxX => salesSpots.isEmpty
      ? 0
      : (salesSpots.length == 1 ? 1 : salesSpots.length - 1.0);

  double get maxY {
    if (salesSpots.isEmpty) return 10;
    final maxSpot = salesSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxVal = totalRevenue > maxSpot ? totalRevenue : maxSpot;
    final rounded = ((maxVal / 5).ceil() * 5).toDouble();
    return rounded == 0 ? 10 : rounded;
  }

  // ----------------- TOTALS -----------------
  int get totalSales {
    int total = 0;
    for (var r in _requests) {
      for (var item in r.itemList) {
        total += item.quantity;
      }
    }
    return total;
  }

  double get totalRevenue {
    double total = 0;
    for (var r in _requests) {
      for (var item in r.itemList) {
        final sp = _spareParts[item.itemDocId];
        if (sp != null) {
          total += sp.salesAmount * item.quantity;
        }
      }
    }
    return total;
  }

  // ----------------- TOP RANKING (YEARLY) -----------------
  List<Map<String, dynamic>> get topRanking {
    final Map<String, int> quantities = {};
    final Map<String, double> revenues = {};

    for (var r in _yearlyRequests) {
      for (var item in r.itemList) {
        final sp = _spareParts[item.itemDocId];
        if (sp != null) {
          quantities[item.itemDocId] =
              (quantities[item.itemDocId] ?? 0) + item.quantity;
          revenues[item.itemDocId] =
              (revenues[item.itemDocId] ?? 0) + (sp.salesAmount * item.quantity);
        }
      }
    }

    final ranking = quantities.keys.map((id) {
      final sp = _spareParts[id];
      return {
        "id": id,
        "name": sp?.name ?? "Unknown",
        "quantity": quantities[id] ?? 0,
        "price": revenues[id] ?? 0.0,
      };
    }).toList();

    ranking.sort((a, b) {
      final qtyCompare = (b["quantity"] as int).compareTo(a["quantity"] as int);
      if (qtyCompare != 0) return qtyCompare;
      return (b["price"] as double).compareTo(a["price"] as double);
    });

    return ranking.take(3).toList();
  }

  // ----------------- LOADERS -----------------
  Future<void> loadSales() async {
    final start = from ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    final end = to ?? DateTime.now();
    await loadRequests(start, end);
  }

  Future<void> loadRequests(DateTime from, DateTime to) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 🔹 Only keep APPROVED requests
      final fetched = await _repository.fetchPartRequests(from, to);
      _requests = fetched.where((r) => r.status == "approved").toList();

      // Load spare parts for filtered requests
      final ids = _requests.expand((r) => r.itemList.map((i) => i.itemDocId)).toSet();
      for (var id in ids) {
        if (!_spareParts.containsKey(id)) {
          final sp = await _repository.fetchSparePart(id);
          if (sp != null) _spareParts[id] = sp;
        }
      }

      // 🔹 ALSO load yearly requests (for top 3), only APPROVED
      final now = DateTime.now();
      final yStart = DateTime(now.year, 1, 1);
      final yEnd = DateTime(now.year, 12, 31);
      final yearlyFetched = await _repository.fetchPartRequests(yStart, yEnd);
      _yearlyRequests =
          yearlyFetched.where((r) => r.status == "approved").toList();

      // Load spare parts for yearly requests
      final yearIds = _yearlyRequests.expand((r) => r.itemList.map((i) => i.itemDocId)).toSet();
      for (var id in yearIds) {
        if (!_spareParts.containsKey(id)) {
          final sp = await _repository.fetchSparePart(id);
          if (sp != null) _spareParts[id] = sp;
        }
      }

    } catch (e) {
      debugPrint("Error loading sales data: $e");
      _requests = [];
      _yearlyRequests = [];
      _spareParts = {};
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshRequests(DateTime from, DateTime to) async {
    await loadRequests(from, to);
  }
}
