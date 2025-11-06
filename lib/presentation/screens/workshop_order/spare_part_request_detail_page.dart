import 'package:flutter/material.dart';
import 'package:sparix/presentation/screens/workshop_order/spare_part_request_invoice.dart';
import 'package:sparix/data/models/part_request.dart';
import 'package:sparix/data/repositories/part_request_repository.dart';

class SparePartRequestDetailPage extends StatefulWidget {
  final String documentId;
  final String requestId;
  final String status;
  final Color statusColor;

  const SparePartRequestDetailPage({
    super.key,
    required this.documentId,
    required this.requestId,
    this.status = "pending",
    this.statusColor = Colors.orange,
  });

  @override
  State<SparePartRequestDetailPage> createState() => _SparePartRequestDetailPageState();
}

class _SparePartRequestDetailPageState extends State<SparePartRequestDetailPage> {
  final PartRequestRepository _repository = PartRequestRepository();
  Map<String, dynamic>? requestData;
  bool isLoading = true;
  bool isUpdatingStatus = false;
  String debugInfo = "";

  @override
  void initState() {
    super.initState();
    _loadRequestData();
  }

  Future<void> _loadRequestData() async {
    try {
      PartRequest? request = await _repository.getPartRequestById(widget.requestId);

      if (request != null) {
        Map<String, dynamic> displayData = await _repository.getRequestDisplayData(request);

        if (mounted) {
          setState(() {
            requestData = displayData;
            isLoading = false;
          });
        }
      } else {
        debugInfo += "Request not found\n";
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugInfo += "Error: $e\n";
      print('Error loading request data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Part Request / Issue",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading request data...'),
          ],
        ),
      );
    }

    if (requestData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text('Request not found'),
            const SizedBox(height: 16),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    PartRequest request = requestData!['request'];
    Map<String, dynamic> customerInfo = requestData!['customerInfo'];
    Map<String, dynamic> shippingAddress = requestData!['shippingAddress'];
    List<Map<String, dynamic>> itemsWithDetails = requestData!['itemsWithDetails'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: const Color(0xFFF3F3F3),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      request.requestId,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.statusColor,
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
                Text(
                  "${customerInfo['name']}\n${customerInfo['phone']}",
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Shipping Address",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  shippingAddress['workshopName'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  shippingAddress['address'],
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),

                Text(
                  "Order Date: ${_formatDateTime(request.orderDate)}",
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Remark :",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  request.remark.isNotEmpty ? request.remark : 'No remark provided',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 32,
              thickness: 1,
              color: Color(0x14000000),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Items",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          if (itemsWithDetails.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No items found',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...itemsWithDetails.map((itemData) =>
                _buildItemCard(
                  itemData['detail'],
                  itemData['quantity'],
                  itemData['subtotal'],
                  hasEnoughStock: itemData['hasEnoughStock'] ?? true,
                  stockWarning: itemData['stockWarning'],
                  showStockInfo: request.status.toLowerCase() != 'approved',
                ),
            ),

          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Total: RM ${request.totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (requestData == null) return const SizedBox.shrink();

    PartRequest request = requestData!['request'];
    bool allItemsHaveStock = requestData!['allItemsHaveStock'] ?? false;

    if (request.status.toLowerCase() == 'approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoicePage(requestId: widget.requestId),
                ),
              );
            },
            child: const Text(
              "View Invoice",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    //only show approve button for on hold
    if (request.status.toLowerCase() == 'on hold') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: allItemsHaveStock ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: (isUpdatingStatus || !allItemsHaveStock) ? null : () => _updateStatus("approved"),
                child: isUpdatingStatus
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  allItemsHaveStock ? "Approve" : "Insufficient Stock",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // show on hold and approve button for pending
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: isUpdatingStatus ? null : () => _updateStatus("on hold"),
                  child: isUpdatingStatus
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "On Hold",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: allItemsHaveStock ? Colors.green : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: (isUpdatingStatus || !allItemsHaveStock) ? null : () => _updateStatus("approved"),
                  child: isUpdatingStatus
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    allItemsHaveStock ? "Approve" : "Insufficient Stock",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      isUpdatingStatus = true;
    });

    try {
      bool success = await _repository.updatePartRequestStatus(
          widget.documentId,
          newStatus
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${newStatus.toUpperCase()} successfully'),
            backgroundColor: Colors.green,
          ),
        );

        if (newStatus.toLowerCase() == 'approved') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => InvoicePage(requestId: widget.requestId),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingStatus = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}   ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'pm' : 'am'}";
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildItemCard(ItemDetail? itemDetail, int quantity, double subtotal, {
    bool hasEnoughStock = true,
    String? stockWarning,
    bool showStockInfo = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildItemImage(itemDetail?.imagePath ?? ''),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemDetail?.title ?? 'Item not found',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            color: itemDetail == null ? Colors.red : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (itemDetail != null && showStockInfo) ...[
                          Text(
                            "Available: ${itemDetail.stockQuantity}",
                            style: TextStyle(
                              fontSize: 12,
                              color: hasEnoughStock ? Colors.green[600] : Colors.red[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Qty: $quantity",
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                            Text(
                              "RM ${subtotal.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (stockWarning != null && showStockInfo) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red[600], size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          stockWarning,
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0x14000000),
          ),
        ),
      ],
    );
  }

  Widget _buildItemImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.asset(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
  }
}