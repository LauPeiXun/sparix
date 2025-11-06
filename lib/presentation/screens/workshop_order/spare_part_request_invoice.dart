import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sparix/data/models/part_request.dart';
import 'package:sparix/data/repositories/part_request_repository.dart';

class InvoicePage extends StatefulWidget {
  final String requestId;
  
  const InvoicePage({super.key, required this.requestId});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final PartRequestRepository _repository = PartRequestRepository();
  Map<String, dynamic>? requestData;
  bool isLoading = true;

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
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading request data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  
  Future<void> _downloadInvoicePDF() async {
    if (requestData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request data not loaded yet. Please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
        Permission.mediaLibrary,
      ].request();

      bool hasPermission = statuses[Permission.storage]?.isGranted == true ||
                          statuses[Permission.manageExternalStorage]?.isGranted == true ||
                          statuses[Permission.mediaLibrary]?.isGranted == true;

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to save PDF files'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Generating PDF..."),
            ],
          ),
        ),
      );

      // generate PDF
      final pdf = await _generatePDF();
      
      String fileName = 'Invoice_${widget.requestId}.pdf';
      String? filePath;

      try {
        String downloadsPath = '/storage/emulated/0/Download';
        Directory downloadsDir = Directory(downloadsPath);
        
        if (await downloadsDir.exists()) {
          filePath = '$downloadsPath/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(pdf);
          print('PDF saved to Downloads: $filePath');
        } else {
          throw Exception('Downloads directory not accessible');
        }
      } catch (e) {
        print('Downloads directory failed: $e');
        
        try {
          Directory? externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            String publicPath = '${externalDir.path}/PDFs';
            Directory publicDir = Directory(publicPath);
            if (!await publicDir.exists()) {
              await publicDir.create(recursive: true);
            }
            
            filePath = '$publicPath/$fileName';
            final file = File(filePath);
            await file.writeAsBytes(pdf);
            print('PDF saved to external storage: $filePath');
          } else {
            throw Exception('External storage not available');
          }
        } catch (e) {
          print('External directory failed: $e');

          Directory appDocDir = await getApplicationDocumentsDirectory();
          filePath = '${appDocDir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(pdf);
          print('PDF saved to app documents: $filePath');
        }
      }

      Navigator.of(context).pop();
      String locationMessage = '';
      if (filePath.contains('/Download/')) {
        locationMessage = 'PDF saved to Downloads folder\nFile: $fileName\nYou can find it in your device\'s Downloads folder';
      } else if (filePath.contains('/PDFs/')) {
        locationMessage = 'PDF saved to app storage\nFile: $fileName\nPath: $filePath\nUse a file manager to locate it';
      } else {
        locationMessage = 'PDF saved successfully\nFile: $fileName\nPath: $filePath';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationMessage),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 7),
        ),
      );
      
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<Uint8List> _generatePDF() async {
    final pdf = pw.Document();

    PartRequest request = requestData!['request'];
   Workshop? workshop = requestData!['workshop'];
    List<Map<String, dynamic>> itemsWithDetails = requestData!['itemsWithDetails'];
    Map<String, dynamic> customerInfo = requestData!['customerInfo'];
    Map<String, dynamic> shippingAddress = requestData!['shippingAddress'];

    String invoiceDate = '${request.orderDate.day}/${request.orderDate.month}/${request.orderDate.year}';
    DateTime dueDate = request.orderDate.add(const Duration(days: 7));
    String dueDateStr = '${dueDate.day}/${dueDate.month}/${dueDate.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Sparix Sdn Bhd', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('A3-3A, Block A,'),
                      pw.Text('Ativo Plaza,'),
                      pw.Text('Bandar Sri Damansara,'),
                      pw.Text('52200 Kuala Lumpur.'),
                      pw.SizedBox(height: 4),
                      pw.Text('Mobile: +60 16-222-0515'),
                      pw.Text('Email: admin@getsparix.com.my'),
                    ],
                  ),
                ],
              ),
              
              pw.Divider(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      pw.Text(shippingAddress['workshopName'] ?? 'Unknown Workshop', 
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(shippingAddress['address'] ?? 'No address provided'),
                      pw.SizedBox(height: 6),
                      pw.Text('Contact: ${customerInfo['name'] ?? 'Unknown'}'),
                      pw.Text('Phone: ${customerInfo['phone'] ?? 'Unknown'}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Invoice No: INV-${request.requestId.replaceAll('SPR', '')}'),
                      pw.Text('Request ID: ${request.requestId}'),
                      pw.Text('Invoice Date: $invoiceDate'),
                      pw.Text('Due Date: $dueDateStr'),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),

              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...itemsWithDetails.map((itemData) {
                    ItemDetail item = itemData['detail'];
                    int quantity = itemData['quantity'];
                    double subtotal = itemData['subtotal'];
                    
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item.title),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(quantity.toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('RM${item.unitPrice.toStringAsFixed(2)}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('RM${subtotal.toStringAsFixed(2)}'),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Subtotal: RM${request.totalPrice.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
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
          style: TextStyle(
              color: Colors.black,
              fontSize: 18
          ),
        ),
      ),
      body: isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading invoice data...'),
              ],
            ),
          )
        : requestData == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Failed to load invoice data'),
                ],
              ),
            )
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.download, size: 28),
                    onPressed: () {
                      _downloadInvoicePDF();
                    },
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "INVOICE",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Sparix Sdn Bhd",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("A3-3A, Block A,\nAtivo Plaza,\nBandar Sri Damansara,\n52200 Kuala Lumpur.", style: TextStyle(fontSize: 10)),
                            SizedBox(height: 4),
                            Text("Mobile: +60 16-222-0515", style: TextStyle(fontSize: 10)),
                            Text("Email: admin@getsparix.com.my", style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    child: Divider(
                      height: 15,
                      thickness: 1,
                      color: Colors.black26,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Bill To",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text(requestData!['shippingAddress']['workshopName'] ?? 'Unknown Workshop', 
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(requestData!['shippingAddress']['address'] ?? 'No address provided', 
                                style: const TextStyle(fontSize: 10)),
                            const SizedBox(height: 4),
                            Text("Contact: ${requestData!['customerInfo']['name'] ?? 'Unknown'}", 
                                style: const TextStyle(fontSize: 10)),
                            Text("Phone: ${requestData!['customerInfo']['phone'] ?? 'Unknown'}", 
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Invoice No :", style: TextStyle(fontSize: 10)),
                                Text("INV-${(requestData!['request'] as PartRequest).requestId.replaceAll('SPR', '')}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 10)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Request ID :", style: TextStyle(fontSize: 10)),
                                Text((requestData!['request'] as PartRequest).requestId,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 10)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Invoice Date :", style: TextStyle(fontSize: 10)),
                                Text(_formatDate((requestData!['request'] as PartRequest).orderDate), 
                                    style: const TextStyle(fontSize: 10)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Due Date :", style: TextStyle(fontSize: 10)),
                                Text(_formatDate((requestData!['request'] as PartRequest).orderDate.add(const Duration(days: 7))), 
                                    style: const TextStyle(fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Table(
                    border: TableBorder.all(color: Colors.black12, width: 1),
                    columnWidths: const {
                      0: FlexColumnWidth(4), // Item
                      1: FlexColumnWidth(1), // Qty
                      2: FlexColumnWidth(2), // Total
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFFF3F3F3)),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("Item",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("Qty",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("Total",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),

                      ...(requestData!['itemsWithDetails'] as List<Map<String, dynamic>>).map((itemData) {
                        ItemDetail item = itemData['detail'];
                        int quantity = itemData['quantity'];
                        double subtotal = itemData['subtotal'];
                        
                        return _buildTableRow(
                          item.title,
                          quantity.toString(),
                          "RM${subtotal.toStringAsFixed(2)}"
                        );
                      }),
                    ],
                  ),

                  Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      "Subtotal      RM${(requestData!['request'] as PartRequest).totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TableRow _buildTableRow(String item, String qty, String total) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(item, style: const TextStyle(fontSize: 10)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(qty, style: const TextStyle(fontSize: 10)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(total, style: const TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}
