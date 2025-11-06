import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/application/providers/sales_revenue_report_provider.dart';
import 'package:sparix/presentation/screens/report/itemdetail_page.dart';


class SalesLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final double maxY;
  final double minX;
  final double maxX;

  const SalesLineChart({
    super.key,
    required this.spots,
    required this.maxY,
    required this.minX,
    required this.maxX,
  });

  @override
  Widget build(BuildContext context) {

    final interval = maxY / 5;

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval, // 动态 interval
                getTitlesWidget: (value, meta) {
                  if (value % interval == 0) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



/// Sales report page
class SalesRevenueReportPage extends StatefulWidget {
  const SalesRevenueReportPage({super.key});

  @override
  State<SalesRevenueReportPage> createState() =>
      _SalesRevenueReportPageState();
}

class _SalesRevenueReportPageState extends State<SalesRevenueReportPage> {
  // 🔹 Calendar State
  DateTime? _from;
  DateTime? _to;
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.enforced;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final DateTime _firstDay = DateTime(DateTime.now().year - 5, 1, 1);
  final DateTime _lastDay = DateTime(DateTime.now().year + 5, 12, 31);

  @override
  void initState() {
    super.initState();
    // Default filter = current month
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month + 1, 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesRevenueProvider>().loadSales();
    });
  }

  String _fmt(DateTime? d) {
    if (d == null) return '--/--/----';
    return '${d.day.toString().padLeft(2, '0')}/${d.month}/${d.year}';
  }

  Widget _pillDate(DateTime? d) {
    final isPlaceholder = d == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _fmt(d),
        style: TextStyle(
          fontSize: 14,
          color: isPlaceholder ? Colors.black45 : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _applyRangeToFilter(DateTime? start, DateTime? end) {
    setState(() {
      _from = start == null ? null : DateTime(start.year, start.month, start.day);
      _to = end == null ? null : DateTime(end.year, end.month, end.day);
    });

    if (_from != null && _to != null) {
      context.read<SalesRevenueProvider>()
        ..from = _from
        ..to = _to
        ..loadSales();
    }
  }

  void _clearDates() {
    setState(() {
      _from = null;
      _to = null;
      _rangeStart = null;
      _rangeEnd = null;
      _rangeSelectionMode = RangeSelectionMode.enforced;
    });

    context.read<SalesRevenueProvider>()
      ..from = DateTime(DateTime.now().year, DateTime.now().month, 1)
      ..to = DateTime.now()
      ..loadSales();
  }

  Future<void> _openCalendarDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) {
        DateTime focused = _focusedDay;
        DateTime? start = _rangeStart ?? _from;
        DateTime? end = _rangeEnd ?? _to;

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: StatefulBuilder(
            builder: (ctx, setSt) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TableCalendar(
                        firstDay: _firstDay,
                        lastDay: _lastDay,
                        focusedDay: focused,
                        calendarFormat: _calendarFormat,
                        rangeStartDay: start,
                        rangeEndDay: end,
                        rangeSelectionMode: _rangeSelectionMode,
                        headerStyle: HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                        ),
                        onPageChanged: (fd) => setSt(() => focused = fd),
                        onRangeSelected: (s, e, f) {
                          setSt(() {
                            start = s;
                            end = e;
                            focused = f;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        children: [
                          Text('From: ${_fmt(start)}   To: ${_fmt(end)}'),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _focusedDay = focused;
                                _rangeStart = start;
                                _rangeEnd = end;
                                _applyRangeToFilter(start, end);
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesRevenueProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: const CustomAppBar(),
          bottomNavigationBar: const CustomNavBar(currentIndex: 3),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Date filter row
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: [
                        const Text('From', style: TextStyle(fontSize: 14)),
                        _pillDate(_from),
                        const Text('To', style: TextStyle(fontSize: 14)),
                        _pillDate(_to),
                        SizedBox(
                          height: 32,
                          width: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 18,
                            tooltip: 'Pick range',
                            onPressed: _openCalendarDialog,
                            icon: const Icon(Icons.calendar_month, color: Colors.black),
                          ),
                        ),
                        if (_from != null || _to != null)
                          SizedBox(
                            height: 32,
                            width: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              tooltip: 'Clear',
                              onPressed: _clearDates,
                              icon: const Icon(Icons.close, color: Colors.black54),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 🔹 Line Chart
                const Text(
                  "Total Sales in Selected Period",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SalesLineChart(
                  spots: provider.salesSpots,
                  maxY: provider.maxY,
                  minX: provider.minX,
                  maxX: provider.maxX,
                ),

                const SizedBox(height: 16),
                Text("Total item sales: ${provider.totalSales}"),
                Text("Total revenue: RM${provider.totalRevenue.toStringAsFixed(2)}"),

                const Divider(height: 32),

                // 🔹 Top 3 ranking sales
                Text(
                  "Top 3 Ranking Item Sales in Year ${DateTime.now().year}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                for (int i = 0; i < provider.topRanking.length; i++)
                  _rankingItem(
                    context,
                    i + 1,
                    provider.topRanking[i]['id'],
                    provider.topRanking[i]['name'],
                    provider.topRanking[i]['quantity'],
                    provider.topRanking[i]['price'],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Ranking Item Widget with navigation
  Widget _rankingItem(
      BuildContext context,
      int rank,
      String itemId,
      String name,
      int currentMonth,
      double price,
      ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(rank.toString())),
        title: Text("Item Name: $name"),
        subtitle: Text("Unit Sold: $currentMonth"),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemDetailPage(itemId: itemId),
            ),
          );
        },
      ),
    );
  }
}
