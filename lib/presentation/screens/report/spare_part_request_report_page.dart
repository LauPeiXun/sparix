import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/application/providers/request_report_provider.dart';
import 'package:sparix/data/models/request_report.dart';
import 'package:table_calendar/table_calendar.dart';

class SparePartRequestReportPage extends StatefulWidget {
  const SparePartRequestReportPage({super.key});

  @override
  State<SparePartRequestReportPage> createState() =>
      _SparePartRequestReportState();
}

class _SparePartRequestReportState extends State<SparePartRequestReportPage> {
  @override
  void initState() {
    super.initState();


    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month + 1, 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }


  Future<void> _loadData() async {
    final provider =
    Provider.of<RequestReportProvider>(context, listen: false);
    await provider.loadReports();
  }

  // 🔹 Calendar & Date Range State
  DateTime? _from;
  DateTime? _to;

  final DateTime _firstDay = DateTime(DateTime
      .now()
      .year - 5, 1, 1);
  final DateTime _lastDay = DateTime(DateTime
      .now()
      .year + 5, 12, 31);
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.enforced;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  String _fmt(DateTime? d) {
    if (d == null) return '--/--/----';
    return '${d.day.toString().padLeft(2, '0')}/${d.month}/${d.year}';
  }

  void _applyRangeToFilter(DateTime? start, DateTime? end) {
    setState(() {
      _from = (start == null)
          ? null
          : DateTime(start.year, start.month, start.day);
      _to = (end == null) ? null : DateTime(end.year, end.month, end.day);
    });
  }

  void _clearDates() {
    setState(() {
      _from = null;
      _to = null;
      _rangeStart = null;
      _rangeEnd = null;
      _rangeSelectionMode = RangeSelectionMode.enforced;
    });
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

  Future<void> _openCalendarDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) {
        DateTime focused = _focusedDay;
        DateTime? start = _rangeStart ?? _from;
        DateTime? end = _rangeEnd ?? _to;

        return Dialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        onDaySelected: (d, f) {
                          setSt(() {
                            if (start != null && end == null) {
                              if (d.isBefore(start!)) {
                                end = start;
                                start = d;
                              } else {
                                end = d;
                              }
                            } else {
                              start = d;
                              end = null;
                            }
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
    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Consumer<RequestReportProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF5CE65C)),
                    ),
                  ),
                );
              }

              // 🔹 Apply date filter to reports
              List<RequestReport> reports = provider.reports;
              if (_from != null && _to != null) {
                reports = reports
                    .where((r) =>
                r.createdAt.isAfter(_from!.subtract(const Duration(days: 1))) &&
                    r.createdAt.isBefore(_to!.add(const Duration(days: 1))))
                    .toList();
              }

              final total = reports.length;
              final approved = reports
                  .where((r) => r.status.toLowerCase() == "approved")
                  .length;
              final rejected = reports
                  .where((r) => r.status.toLowerCase() == "rejected")
                  .length;
              final pending = reports
                  .where((r) => r.status.toLowerCase() == "pending")
                  .length;
              final onhold = reports
                  .where((r) => r.status.toLowerCase() == "on hold")
                  .length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 12),
                  _buildDateRangeFilter(),
                  const SizedBox(height: 20),
                  _buildOverviewCards(total, approved, rejected),
                  const SizedBox(height: 40),
                  _buildPieChart(total, approved, pending, rejected, onhold),
                  const SizedBox(height: 20),
                  _buildRequestTable(reports),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 2),
    );
  }

  Widget _buildTitle() {
    return const Text(
      "Spare Part Request Report",
      style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildDateRangeFilter() {
    return Center(
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
            const Text('TO', style: TextStyle(fontSize: 14)),
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
    );
  }

  Widget _buildOverviewCards(int total, int approved, int rejected) {
    return Row(
      children: [
        Expanded(
          child: _overviewCard(
              "Total Requests", total.toString(), Colors.black87),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _overviewCard("Approved", approved.toString(), Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _overviewCard("Rejected", rejected.toString(), Colors.red),
        ),
      ],
    );
  }

  Widget _overviewCard(String title, String value,
      Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey,
            blurRadius: 4)],
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight:
              FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(fontSize: 12,
                  color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildPieChart(int total, int approved, int pending, int rejected, int onhold) {
    if (total == 0) return const Center(child: Text("No report data"));

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: approved.toDouble(),
                  title: "${((approved / total) * 100).toStringAsFixed(0)}%",
                  radius: 80,
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  color: Colors.yellow[300]!,
                  value: pending.toDouble(),
                  title: "${((pending / total) * 100).toStringAsFixed(0)}%",
                  radius: 80,
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: rejected.toDouble(),
                  title: "${((rejected / total) * 100).toStringAsFixed(0)}%",
                  radius: 80,
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  color: Colors.blue,
                  value: onhold.toDouble(),
                  title: "${((onhold / total) * 100).toStringAsFixed(0)}%",
                  radius: 80,
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legend("Approved", Colors.green, approved, total),
                _legend("Pending", Colors.yellow[300]!, pending, total),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legend("Rejected", Colors.red, rejected, total),
                _legend("On Hold", Colors.blue, onhold, total),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget _legend(String label, Color color, int count, int total) {
    final percent =
    total > 0 ? (count / total * 100).toStringAsFixed(0) : "0";
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 6),
        Text("$label $percent%"),
      ],
    );
  }

  Widget _buildRequestTable(List<RequestReport> reports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Row(
          children: const [
            Expanded(
              child: Text("Request ID",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Text("Request Type",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Text("Status",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const Divider(),
        ...reports.map((r) =>
            Row(
              children: [
                Expanded(child: Text(r.requestId)), // ✅ Request ID
                Expanded(child: Text(r.requestType)), // ✅ Request Type
                Expanded(
                  child: Text(
                    r.status, // ✅ Status
                    style: TextStyle(
                      color: r.status.toLowerCase() == "approved"
                          ? Colors.green
                          : r.status.toLowerCase() == "rejected"
                          ? Colors.red
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )),
      ],
    );
  }
}