import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/application/providers/workshop_report_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class WorkshopOrderReportPage extends StatefulWidget {
  const WorkshopOrderReportPage({super.key});

  @override
  State<WorkshopOrderReportPage> createState() => _WorkshopOrderReportPageState();
}

class _WorkshopOrderReportPageState extends State<WorkshopOrderReportPage> {
  DateTime? _from;
  DateTime? _to;
  final TextEditingController _searchController = TextEditingController();
  DateTime _focusedDay = DateTime.now();
  int? _sortColumnIndex;
  final bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<WorkshopReportProvider>(context, listen: false).fetchAllOrders());
  }

  Widget _buildPieChart(int completed, int pending, int total) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: completed.toDouble(),
                    title: '$completed',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: pending.toDouble(),
                    title: '$pending',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildBarChart(int completed, int pending, int total) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: total.toDouble() + 2,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    const style = TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    );
                    switch (value.toInt()) {
                      case 0:
                        return const Text('Completed', style: style);
                      case 1:
                        return const Text('Pending', style: style);
                      default:
                        return const Text('', style: style);
                    }
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    if (value == value.roundToDouble()) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                );
              },
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: completed.toDouble(),
                    color: Colors.green,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: pending.toDouble(),
                    color: Colors.orange,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.green, 'Completed'),
        const SizedBox(width: 20),
        _buildLegendItem(Colors.orange, 'Pending'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _clearDates() {
    setState(() {
      _from = null;
      _to = null;
    });
  }

  String _fmt(DateTime? d) {
    if (d == null) return '--/--/----';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _openCalendarDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) {
        DateTime? start = _from;
        DateTime? end = _to;
        DateTime focused = _focusedDay;

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: StatefulBuilder(
            builder: (ctx, setSt) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TableCalendar(
                      firstDay: DateTime(DateTime.now().year - 5),
                      lastDay: DateTime(DateTime.now().year + 5),
                      focusedDay: focused,
                      rangeStartDay: start,
                      rangeEndDay: end,
                      rangeSelectionMode: RangeSelectionMode.enforced,
                      onPageChanged: (fd) => setSt(() => focused = fd),
                      onRangeSelected: (s, e, f) {
                        setSt(() {
                          start = s;
                          end = e;
                          focused = f;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: const TextStyle(color: Colors.black),
                        weekendTextStyle: const TextStyle(color: Colors.black),
                        selectedTextStyle: const TextStyle(color: Colors.white),
                        todayTextStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                        rangeStartTextStyle: const TextStyle(color: Colors.white),
                        rangeEndTextStyle: const TextStyle(color: Colors.white),
                        withinRangeTextStyle: const TextStyle(color: Colors.black),
                        outsideTextStyle: TextStyle(color: Colors.grey.shade400),
                        selectedDecoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          shape: BoxShape.circle,
                        ),
                        rangeStartDecoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        rangeEndDecoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        withinRangeDecoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        outsideDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        holidayDecoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        weekendDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        titleCentered: true,
                        leftChevronIcon: const Icon(Icons.chevron_left,
                            color: Colors.black, size: 20),
                        rightChevronIcon: const Icon(Icons.chevron_right,
                            color: Colors.black, size: 20),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: const TextStyle(color: Colors.black),
                        weekendStyle: const TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('From: ${_fmt(start)} To: ${_fmt(end)}',
                        style: const TextStyle(color: Colors.black)),
                    const SizedBox(height: 16),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: () {
                            setState(() {
                              _from = start;
                              _to = end;
                              _focusedDay = focused;
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Apply',
                              style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _pillDate(DateTime? d) {
    final isPlaceholder = d == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
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

  Widget _statusChip(String s) {
    final v = s.toLowerCase().trim();
    Color bg;
    Color fg;
    IconData icon;

    if (v == 'completed') {
      bg = Colors.green;
      fg = Colors.green[700]!;
      icon = Icons.check_circle_outline;
    } else if (v == 'pending') {
      bg = Colors.orange;
      fg = Colors.orange[700]!;
      icon = Icons.hourglass_empty;
    } else {
      bg = Colors.blueGrey;
      fg = Colors.blueGrey;
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 4),
        Text(s, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }

  Widget _buildPageTitle() {
    return const Text(
      'Workshop Order Report',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<WorkshopReportProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null) {
              return Center(child: Text(provider.errorMessage!));
            }

            final orders = provider.orders;

            final dateFilteredOrders = orders.where((o) {
              if (_from != null) {
                final startOfDay = DateTime(_from!.year, _from!.month, _from!.day);
                if (o.date.isBefore(startOfDay)) {
                  return false;
                }
              }
              if (_to != null) {
                final endOfDay = DateTime(_to!.year, _to!.month, _to!.day, 23, 59, 59);
                if (o.date.isAfter(endOfDay)) {
                  return false;
                }
              }
              return true;
            }).toList();

            final filteredOrders = dateFilteredOrders.where((o) {
              final search = _searchController.text.toLowerCase();
              return search.isEmpty ||
                  o.code.toLowerCase().contains(search) ||
                  o.status.toLowerCase().contains(search) ||
                  (o.items.isNotEmpty &&
                      provider.products[o.items[0].productId]?.model.toLowerCase().contains(search) == true);
            }).toList();

            final completedCount = filteredOrders.where((o) => o.status.toLowerCase() == 'completed').length;
            final pendingCount = filteredOrders.where((o) => o.status.toLowerCase() == 'pending').length;
            final totalCount = filteredOrders.length;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPageTitle(),
                  const SizedBox(height: 16),

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
                          const Text('From'),
                          _pillDate(_from),
                          const Text('To'),
                          _pillDate(_to),
                          IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: _openCalendarDialog,
                          ),
                          if (_from != null || _to != null)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _clearDates,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Column(
                    children: [
                      _statCard('Total Reports', totalCount.toString(), Colors.blue, Icons.description_outlined),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _statCard('Completed', completedCount.toString(), Colors.green, Icons.check_circle_outline),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard('Pending', pendingCount.toString(), Colors.orange, Icons.hourglass_empty),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Column(
                    children: [
                      Column(
                        children: [
                          const Text('Distribution Pie Chart', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildPieChart(completedCount, pendingCount, totalCount),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Column(
                        children: [
                          const Text('Count Bar Chart', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildBarChart(completedCount, pendingCount, totalCount),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      color: Colors.white,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
                        child: DataTable(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          dataRowMinHeight: 40,
                          dataRowMaxHeight: 100,
                          headingRowHeight: 40,
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAsc,
                          columns: [
                            DataColumn(label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: const Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: const Text('Car Models', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(
                              numeric: true,
                              label: const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                          rows: filteredOrders.map((order) {
                            final carModels = order.items.map((item) {
                              return provider.products[item.productId]?.model ?? '';
                            }).toSet().toList();

                            String carModelsText;
                            if (carModels.isEmpty) {
                              carModelsText = 'No models';
                            } else if (carModels.length == 1) {
                              carModelsText = carModels.first;
                            } else {
                              carModelsText = '${carModels.length} models: ${carModels.join(', ')}';
                            }

                            return DataRow(
                              cells: [
                                DataCell(_statusChip(order.status)),
                                DataCell(Text(order.code, overflow: TextOverflow.ellipsis)),
                                DataCell(
                                  Tooltip(
                                    message: carModels.length > 1 ? carModels.join('\n') : carModelsText,
                                    child: Text(
                                      carModelsText,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                                DataCell(Center(child: Text(order.itemCount.toString()))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 3),
    );
  }

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}