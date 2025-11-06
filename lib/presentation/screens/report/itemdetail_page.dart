import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/data/repositories/salesrevenue_report_repository.dart';
import 'package:sparix/data/models/sales_report.dart'; // SparePart, PartRequest

class ItemDetailPage extends StatefulWidget {
  final String itemId;

  const ItemDetailPage({super.key, required this.itemId});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final SalesRepository _repo = SalesRepository();

  SparePart? _sparePart;
  int lastMonthSales = 0;
  int currentMonthSales = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final part = await _repo.fetchSparePart(widget.itemId);

    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);

    final lastMonthRequests =
    await _repo.fetchPartRequests(lastMonthStart, lastMonthEnd);
    final thisMonthRequests =
    await _repo.fetchPartRequests(thisMonthStart, now);

    int countSales(List<PartRequest> requests) {
      int total = 0;
      for (var r in requests) {
        for (var item in r.itemList) {
          if (item.itemDocId == widget.itemId) {
            total += item.quantity;
          }
        }
      }
      return total;
    }

    setState(() {
      _sparePart = part;
      lastMonthSales = countSales(lastMonthRequests);
      currentMonthSales = countSales(thisMonthRequests);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_sparePart == null) {
      return const Scaffold(
        body: Center(child: Text("Item not found")),
      );
    }

    final double unitPrice = _sparePart!.price;
    final double growthPercentage = lastMonthSales > 0
        ? ((currentMonthSales - lastMonthSales) / lastMonthSales * 100)
        : 0.0;

    final int totalUnits = currentMonthSales;
    final double totalSales = currentMonthSales * unitPrice;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _sparePart!.name,
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 3),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildChartSection(lastMonthSales, currentMonthSales, growthPercentage),
            const SizedBox(height: 20),
            _buildDetailSection(
              _sparePart!.name,
              unitPrice,
              totalUnits,
              totalSales,
              _sparePart!.imageUrl, // ✅ pass image
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(int lastMonth, int currentMonth, double growth) {
    final double rawMax = [
      lastMonth.toDouble(),
      currentMonth.toDouble()
    ].reduce((a, b) => a > b ? a : b);

    // 🔥 Round up maxY to nearest multiple of 5
    double step = (rawMax / 5).ceilToDouble();
    double maxY = step * 5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Text(
            "Total Quantity",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                minY: 0,
                maxY: maxY,
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                      toY: lastMonth.toDouble(),
                      color: Colors.red,
                      width: 50,
                    ),
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(
                      toY: currentMonth.toDouble(),
                      color: Colors.green,
                      width: 50,
                    ),
                  ]),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text("Last Month");
                          case 1:
                            return const Text("This Month");
                          default:
                            return const Text("");
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxY / 5, // ✅ divide into 5 steps
                      getTitlesWidget: (value, _) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5, // ✅ keep grid aligned with labels
                ),
                baselineY: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Growth compared to last month: ${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }


  Widget _buildDetailSection(
      String name,
      double price,
      int totalUnits,
      double totalSales,
      String imageUrl,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ✅ show actual image from Firestore
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow("Item Name:", name),
          const SizedBox(height: 8),
          _buildDetailRow("Unit Price:", "RM${price.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          _buildDetailRow("Total Units Sold:", totalUnits.toString()),
          const SizedBox(height: 8),
          _buildDetailRow("Total Sales:", "RM${totalSales.toStringAsFixed(2)}", isTotal: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade300,
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
