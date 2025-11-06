import 'package:flutter/material.dart';
import 'package:sparix/data/models/damage_report.dart';

class DamageReportDetailsPage extends StatelessWidget {
  final DamageReport report;

  const DamageReportDetailsPage({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Damage Report Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagesSection(),
            _buildReportInfoSection(),
            const SizedBox(height: 10),
            _buildDescriptionSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    if (report.imageUrls.isEmpty) {
      return Container(
        width: double.infinity,
        height: 250,
        color: Colors.grey[100],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey,
          ),
        ),
      );
    }

    // If only one image, display it full width
    if (report.imageUrls.length == 1) {
      return Container(
        width: double.infinity,
        height: 250,
        color: Colors.grey[100],
        child: Image.network(
          report.imageUrls[0],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5CE65C)),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.grey,
              ),
            );
          },
        ),
      );
    }

    // Multiple images - show as a horizontal scrolling gallery
    return Container(
      height: 250,
      color: Colors.grey[100],
      child: PageView.builder(
        itemCount: report.imageUrls.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: Image.network(
                  report.imageUrls[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5CE65C)),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              // Image counter indicator
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}/${report.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportInfoSection() {
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

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report ID and Type Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Report #${report.reportId.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: getReportTypeColor(report.reportType),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  report.reportType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Part Name
          Text(
            report.partName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Quantity', '${report.quantity}'),
                _buildDetailRow('Date Reported', formatDate(report.dateReported)),
                _buildDetailRow('Reported By', report.reportedBy),
                _buildDetailRow('Report Type', report.reportType),
                _buildDetailRow('Created At', formatDateTime(report.createdAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDescriptionSection() {
    if (report.description == null || report.description!.isEmpty) {
      return Container();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description / Remarks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              report.description!,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(
            ':  ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}