import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/application/providers/damage_report_provider.dart';
import 'package:sparix/data/models/damage_report.dart';

class DamageSparePartAnalytics extends StatefulWidget {
  const DamageSparePartAnalytics({super.key});

  @override
  State<DamageSparePartAnalytics> createState() => _DamageSparePartAnalyticsState();
}

class _DamageSparePartAnalyticsState extends State<DamageSparePartAnalytics> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<DamageReportProvider>(context, listen: false);
    await provider.loadDamageReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF5CE65C),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Consumer<DamageReportProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5CE65C)),
                    ),
                  ),
                );
              }

              if (provider.error != null) {
                return _buildErrorWidget(provider.error!);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageTitle(),
                  const SizedBox(height: 20),
                  _buildOverviewCards(provider.damageReports),
                  const SizedBox(height: 20),
                  _buildReportTypeChart(provider.damageReports),
                  const SizedBox(height: 20),
                  _buildQuantityHistogram(provider.damageReports),
                  const SizedBox(height: 20),
                  _buildRankingSection(provider.damageReports),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 3),
    );
  }

  Widget _buildPageTitle() {
    return const Text(
      'Damage Report Analytics',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics data',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5CE65C),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(List<DamageReport> reports) {
    final totalReports = reports.length;
    final damageReports = reports.where((r) => r.reportType.toLowerCase() == 'damage').length;
    final lostReports = reports.where((r) => r.reportType.toLowerCase() == 'lost').length;
    final totalQuantity = reports.fold<int>(0, (sum, report) => sum + report.quantity);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                title: 'Total Reports',
                value: totalReports.toString(),
                color: Colors.blue,
                icon: Icons.description,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                title: 'Total Qty',
                value: totalQuantity.toString(),
                color: Colors.green,
                icon: Icons.inventory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                title: 'Lost',
                value: lostReports.toString(),
                color: Colors.red,
                icon: Icons.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                title: 'Damage',
                value: damageReports.toString(),
                color: Colors.orange,
                icon: Icons.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeChart(List<DamageReport> reports) {
    final damageCount = reports.where((r) => r.reportType.toLowerCase() == 'damage').length;
    final lostCount = reports.where((r) => r.reportType.toLowerCase() == 'lost').length;
    
    if (damageCount == 0 && lostCount == 0) {
      return _buildEmptyChart();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  if (damageCount > 0)
                    PieChartSectionData(
                      color: Colors.orange,
                      value: damageCount.toDouble(),
                      title: '$damageCount',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (lostCount > 0)
                    PieChartSectionData(
                      color: Colors.red,
                      value: lostCount.toDouble(),
                      title: '$lostCount',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (damageCount > 0) ...[
                _buildLegendItem('Damage', Colors.orange, damageCount),
                const SizedBox(width: 20),
              ],
              if (lostCount > 0)
                _buildLegendItem('Lost', Colors.red, lostCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Report Types Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No reports available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityHistogram(List<DamageReport> reports) {
    // Group reports by part name and calculate quantities
    final Map<String, int> partQuantities = {};
    
    for (final report in reports) {
      final partName = report.partName;
      partQuantities[partName] = (partQuantities[partName] ?? 0) + report.quantity;
    }

    // Sort by quantity and take top 6 for display
    final sortedEntries = partQuantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topParts = sortedEntries.take(6).toList();

    if (topParts.isEmpty) {
      return _buildEmptyHistogram();
    }

    // Find max value for scaling
    final maxValue = topParts.first.value.toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Parts by Quantity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2, // Add some padding to top
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final partName = topParts[group.x.toInt()].key;
                      final quantity = rod.toY.round();
                      return BarTooltipItem(
                        '$partName\nQuantity: $quantity',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < topParts.length) {
                          final partName = topParts[value.toInt()].key;
                          // Truncate long names
                          final displayName = partName.length > 8 
                              ? '${partName.substring(0, 8)}...'
                              : partName;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    left: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                barGroups: topParts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final quantity = entry.value.value;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: quantity.toDouble(),
                        color: _getBarColor(index),
                        width: 24,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBarColor(int index) {
    final colors = [
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.indigo[400]!,
    ];
    return colors[index % colors.length];
  }

  Widget _buildEmptyHistogram() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Top Parts by Quantity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),
          Icon(
            Icons.bar_chart,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No parts data available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingSection(List<DamageReport> reports) {
    // Group reports by part name and calculate total quantity
    final Map<String, int> partQuantities = {};
    final Map<String, int> partDamageCount = {};
    final Map<String, int> partLostCount = {};
    
    for (final report in reports) {
      final partName = report.partName;
      partQuantities[partName] = (partQuantities[partName] ?? 0) + report.quantity;
      
      if (report.reportType.toLowerCase() == 'damage') {
        partDamageCount[partName] = (partDamageCount[partName] ?? 0) + report.quantity;
      } else if (report.reportType.toLowerCase() == 'lost') {
        partLostCount[partName] = (partLostCount[partName] ?? 0) + report.quantity;
      }
    }

    // Sort by total quantity descending
    final sortedEntries = partQuantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.leaderboard,
                color: Colors.green[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Most Affected Parts Ranking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sortedEntries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No parts data available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...sortedEntries.take(10).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final partEntry = entry.value;
              final partName = partEntry.key;
              final totalQuantity = partEntry.value;
              final damageQty = partDamageCount[partName] ?? 0;
              final lostQty = partLostCount[partName] ?? 0;

              return _buildRankingItem(
                rank: index + 1,
                partName: partName,
                totalQuantity: totalQuantity,
                damageQuantity: damageQty,
                lostQuantity: lostQty,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRankingItem({
    required int rank,
    required String partName,
    required int totalQuantity,
    required int damageQuantity,
    required int lostQuantity,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Rank number
          Text(
            '$rank',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          
          // Part name
          Expanded(
            child: Text(
              partName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Total quantity
          Text(
            totalQuantity.toString(),
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}