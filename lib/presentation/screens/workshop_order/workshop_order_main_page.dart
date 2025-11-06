import 'package:flutter/material.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'spare_part_request_detail_page.dart';
import 'package:sparix/data/models/part_request.dart';
import 'package:sparix/data/repositories/part_request_repository.dart';

class WorkshopOrderMainPage extends StatefulWidget {
  const WorkshopOrderMainPage({super.key});

  @override
  State<WorkshopOrderMainPage> createState() => _WorkshopOrderMainPageState();
}

class _WorkshopOrderMainPageState extends State<WorkshopOrderMainPage> {
  final TextEditingController _searchController = TextEditingController();
  final PartRequestRepository _repository = PartRequestRepository();
  List<PartRequest> _searchResults = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Part Request / Issue',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Search for....",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (!_isSearching)
              const TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.black,
                tabs: [
                  Tab(text: "Pending"),
                  Tab(text: "Approved"),
                  Tab(text: "On Hold"),
                ],
              ),

            Expanded(
              child: _isSearching
                  ? _buildSearchResults()
                  : TabBarView(
                children: [
                  _buildRequestList("pending"),
                  _buildRequestList("approved"),
                  _buildRequestList("on hold"),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: const CustomNavBar(currentIndex: 1),
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    if (query.isNotEmpty) {
      _performSearch(query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults.clear();
    });
  }

  Future<void> _performSearch(String query) async {
    List<PartRequest> results = await _repository.searchPartRequests(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No results found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(context, _searchResults[index]);
      },
    );
  }

  Widget _buildRequestList(String filterStatus) {
    return StreamBuilder<List<PartRequest>>(
      stream: _repository.getFilteredRequestsStream(filterStatus),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Trigger rebuild
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No $filterStatus requests found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        List<PartRequest> requests = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(context, requests[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, PartRequest request) {
    Color statusColor;
      switch (request.status.toLowerCase()) {
        case 'pending':
          statusColor = Colors.orange;
          break;
        case 'approved':
          statusColor = Colors.green;
          break;
        case 'on hold':
          statusColor = Colors.blue;
          break;
        default:
          statusColor = Colors.grey;

    }

    String formattedDate = '${request.orderDate.day}/${request.orderDate.month}/${request.orderDate.year}';
    String formattedTime = '${request.orderDate.hour}.${request.orderDate.minute.toString().padLeft(2, '0')}${request.orderDate.hour >= 12 ? 'pm' : 'am'}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SparePartRequestDetailPage(
              documentId: request.id!,
              requestId: request.requestId,
              status: request.status,
              statusColor: statusColor,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey, // border color
            width: 0.5,           // border width
          ),
        ),

        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request.requestId,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Request", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(request.requestType, style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Price", style: TextStyle(fontSize: 12, color: Colors.grey)),
              FutureBuilder<double>(
                future: _repository.getTotalPriceForRequest(request),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  } else if (snapshot.hasData) {
                    return Text(
                      "RM ${snapshot.data!.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    );
                  } else {
                    return const Text(
                      "RM 0.00",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Date", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text("$formattedDate $formattedTime", style: const TextStyle(fontSize: 13)),
            ],
          ),
        ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}