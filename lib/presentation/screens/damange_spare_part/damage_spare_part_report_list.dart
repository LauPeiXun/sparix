import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/presentation/screens/damange_spare_part/damage_spare_part_report.dart';
import 'package:sparix/presentation/screens/damange_spare_part/damage_report_details_page.dart';
import 'package:sparix/application/providers/damage_report_provider.dart';
import 'package:sparix/data/models/damage_report.dart';

class DamageSparePartReportList extends StatefulWidget {
  const DamageSparePartReportList({super.key});

  @override
  State<DamageSparePartReportList> createState() => _DamageSparePartReportListState();
}

class _DamageSparePartReportListState extends State<DamageSparePartReportList> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _sortBy = 'time'; // 'time' or 'type'
  List<DamageReport> _filteredReports = [];
  List<DamageReport> _allReports = [];
  bool _isDateFilterActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDamageReports();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDamageReports() async {
    final provider = Provider.of<DamageReportProvider>(context, listen: false);
    await provider.loadDamageReports();
    _updateFilteredReports();
  }

  void _updateFilteredReports() {
    final provider = Provider.of<DamageReportProvider>(context, listen: false);
    _allReports = provider.damageReports;

    // Start with all reports
    List<DamageReport> tempReports = List.from(_allReports);

    // Apply search filter
    String searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      tempReports = tempReports.where((report) {
        return report.partName.toLowerCase().contains(searchQuery) ||
            report.reportType.toLowerCase().contains(searchQuery) ||
            report.reportedBy.toLowerCase().contains(searchQuery) ||
            report.reportId.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Apply date filter only if active
    if (_isDateFilterActive) {
      tempReports = tempReports.where((report) {
        return _isSameDate(report.dateReported, _selectedDate);
      }).toList();
    }

    _filteredReports = tempReports;

    // Apply sorting
    _applySorting();

    setState(() {});
  }

  void _applySorting() {
    if (_sortBy == 'time') {
      _filteredReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'type') {
      _filteredReports.sort((a, b) {
        int typeComparison = a.reportType.compareTo(b.reportType);
        if (typeComparison == 0) {
          // If types are same, sort by time (newest first)
          return b.createdAt.compareTo(a.createdAt);
        }
        return typeComparison;
      });
    }
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _clearDateFilter() {
    setState(() {
      _isDateFilterActive = false;
      _selectedDate = DateTime.now();
    });
    _updateFilteredReports();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Date filter cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Date Filter Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Select specific date
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text('Select Date'),
                subtitle: Text(_isDateFilterActive 
                    ? 'Current: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'
                    : 'Filter by specific date'),
                onTap: () async {
                  Navigator.pop(context);
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Colors.green,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                      _isDateFilterActive = true;
                    });
                    _updateFilteredReports();
                  }
                },
              ),
              
              // Show all reports
              if (_isDateFilterActive)
                ListTile(
                  leading: const Icon(Icons.clear, color: Colors.orange),
                  title: const Text('Show All Reports'),
                  subtitle: const Text('Remove date filter'),
                  onTap: () {
                    Navigator.pop(context);
                    _clearDateFilter();
                  },
                ),
              
              // Today's reports
              ListTile(
                leading: const Icon(Icons.today, color: Colors.green),
                title: const Text('Today\'s Reports'),
                subtitle: Text('Show reports from ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedDate = DateTime.now();
                    _isDateFilterActive = true;
                  });
                  _updateFilteredReports();
                },
              ),
              
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 0),
        child: Column(
          children: [
            _buildSearchSection(),
            const SizedBox(height: 15),
            _buildStatsAndSortSection(),
            const SizedBox(height: 15),
            _buildDamageReportsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DamageSparePartReport(),
            ),
          );
          
          // If report was successfully added, refresh the list
          if (result == true) {
            await _loadDamageReports();
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 1),
    );
  }

  Widget _buildSearchSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by part name, type, reporter, or report ID...',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _updateFilteredReports();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: _isDateFilterActive ? Colors.orange : Colors.green,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                  ),
                ),
                if (_isDateFilterActive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildStatsAndSortSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Reports: ${_filteredReports.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (_isDateFilterActive)
              Text(
                'Filtered by: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        Row(
          children: [
            const Text(
              'Sort by:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                  items: const [
                    DropdownMenuItem(value: 'time', child: Text('Time')),
                    DropdownMenuItem(value: 'type', child: Text('Type')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                      _updateFilteredReports();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDamageReportsList() {
    return Consumer<DamageReportProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5CE65C)),
              ),
            ),
          );
        }

        if (provider.error != null) {
          return Expanded(
            child: Center(
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
                    'Failed to load reports',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDamageReports,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5CE65C),
                    ),
                    child: const Text(
                        'Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        if (_filteredReports.isEmpty) {
          return Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty
                        ? 'No reports match your search'
                        : 'No damage reports yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDamageReports,
            color: const Color(0xFF5CE65C),
            child: ListView.builder(
              itemCount: _filteredReports.length,
              itemBuilder: (context, index) {
                final report = _filteredReports[index];
                return _buildReportCard(report, index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportCard(DamageReport report, int index) {
    Color getReportTypeColor(String type) {
      switch (type.toLowerCase()) {
        case 'damage':
          return Colors.orange;
        case 'lost':
          return Colors.red;
        case 'request':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Report #${report.reportId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: getReportTypeColor(report.reportType),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                report.reportType,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              report.partName,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Qty : ${report.quantity}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${report.dateReported.day}/${report.dateReported
                      .month}/${report.dateReported.year}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),

          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DamageReportDetailsPage(report: report),
            ),
          );
        },
      ),
    );
  }
}