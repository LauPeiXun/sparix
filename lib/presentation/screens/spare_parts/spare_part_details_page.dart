import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparix/application/providers/product_stream_provider.dart';
import 'package:sparix/data/models/spare_part.dart';
import 'package:sparix/presentation/screens/spare_parts/add_edit_spare_part_screens.dart';

class SparePartDetailsPage extends StatelessWidget {
  final String productId;

  const SparePartDetailsPage({
    super.key,
    required this.productId,
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
          'Spare Part Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () async {
              final streamProvider = Provider.of<ProductStreamProvider>(context, listen: false);
              final navigator = Navigator.of(context);
              
              // Get the product from the stream
              final products = await streamProvider.filteredProductsStream.first;
              final product = products.where((p) => p.productId == productId).firstOrNull;
              
              if (product != null) {
                await navigator.push(
                  MaterialPageRoute(
                    builder: (context) => AddEditSparePartScreen(
                      existingProduct: product,
                    ),
                  ),
                );
                
                // No need to manually refresh - StreamBuilder handles real-time updates
              }
            },
            tooltip: 'Edit',
          ),
        ],
      ),
      body: Consumer<ProductStreamProvider>(
        builder: (context, streamProvider, child) {
          return StreamBuilder<List<Product>>(
            stream: streamProvider.filteredProductsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading product: ${snapshot.error}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final products = snapshot.data ?? [];
              final product = products.where((p) => p.productId == productId).firstOrNull;
              
              if (product == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Product not found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductImageSection(product),
                    _buildProductInfoSection(product),
                    _buildLocationSection(product),
                    const SizedBox(height: 10),
                    _buildDescriptionSection(product),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductImageSection(Product product) {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey[100],
      child: product.imageUrl.isNotEmpty
          ? Image.network(
              product.imageUrl,
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
            )
          : const Center(
              child: Icon(
                Icons.build,
                size: 64,
                color: Colors.grey,
              ),
            ),
    );
  }

  Widget _buildProductInfoSection(Product product) {
    return Padding(
      padding: const EdgeInsets.only(left: 20,right: 20,top:10,bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          
          // Price and Stock Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment : CrossAxisAlignment.center,
            children: [
              Text(
                '${product.currency} ${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: product.stock >= product.stockThreshold ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Stock: ${product.stock}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
                _buildDetailRow('Wholesale Price', 'RM ${product.price}'),
                _buildDetailRow('Selling Price','RM ${product.salesAmount}'),
                _buildDetailRow('Brand', product.brand),
                _buildDetailRow('Model', product.model),
                _buildDetailRow('Category', product.category),
                _buildDetailRow('Position', product.position),
                _buildDetailRow('Warranty', formatWarrantyMonths(product.warrantyMonths)),
                _buildDetailRow('Stock Threshold',product.stockThreshold.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(Product product) {
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
            'Spare Part Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          // Extra container wrapping the Row:
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLocationItem('Warehouse', product.warehouse),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[400],
                ),
                _buildLocationItem('Rack', product.rack),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[400],
                ),
                _buildLocationItem('Section', product.section),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(Product product) {
    if (product.description.isEmpty) {
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
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          // Extra container wrapping the Row:
          Container(
            width: double.infinity,  // full width of parent
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product.description.join('\n'),
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
            width: 130,
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

  String formatWarrantyMonths(int totalMonths) {
    final years = totalMonths ~/ 12; // integer division
    final months = totalMonths % 12;

    final yearsStr = years > 0 ? '$years ${years == 1 ? 'year' : 'years'}' : '';
    final monthsStr = months > 0 ? '$months ${months == 1 ? 'month' : 'months'}' : '';

    if (years > 0 && months > 0) {
      return '$yearsStr $monthsStr';
    } else if (years > 0) {
      return yearsStr;
    } else if (months > 0) {
      return monthsStr;
    } else {
      return '0 months';
    }
  }
}