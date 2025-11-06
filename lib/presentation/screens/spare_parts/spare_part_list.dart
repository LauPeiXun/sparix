import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/presentation/components/filter_bottom_sheet.dart';
import 'package:sparix/presentation/screens/spare_parts/spare_part_details_page.dart';
import 'package:sparix/application/providers/product_stream_provider.dart';
import 'package:sparix/data/models/spare_part.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // No need to manually load products - StreamBuilder will handle it
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 8,bottom: 0),
        child: Column(
          children: [
            _buildSearchSection(),
            const SizedBox(height: 10),
            Consumer<ProductStreamProvider>(
              builder: (context, streamProvider, child) {
                if (streamProvider.currentFilter.activeFilterCount > 0) {
                  return StreamBuilder<List<Product>>(
                    stream: streamProvider.filteredProductsStream,
                    builder: (context, snapshot) {
                      final productCount = snapshot.hasData ? snapshot.data!.length : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5, left: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$productCount products found',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                streamProvider.clearFilters();
                              },
                              child: const Text(
                                'Clear all filters',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            _buildCatalogSection(),
          ],
        ),
      ),

      bottomNavigationBar: const CustomNavBar(currentIndex: 0),
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
                        hintText: 'Search spare parts...',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        context.read<ProductStreamProvider>().searchProducts(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Consumer<ProductStreamProvider>(
          builder: (context, streamProvider, child) {
            final activeFilters = streamProvider.currentFilter.activeFilterCount;
            return Stack(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: () {
                      _showFilterBottomSheet();
                    },
                  ),
                ),
                if (activeFilters > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '$activeFilters',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCatalogSection() {
    return Expanded(
      child: Consumer<ProductStreamProvider>(
        builder: (context, streamProvider, child) {
          return StreamBuilder<List<Product>>(
            stream: streamProvider.filteredProductsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5CE65C)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
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
                        'Failed to load products',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // StreamBuilder will automatically retry
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5CE65C),
                        ),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              final displayProducts = snapshot.data ?? [];
              
              if (displayProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No result on your search or filter',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final minItemCount = displayProducts.length < 6 ? 6 : displayProducts.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        // StreamBuilder will automatically refresh from Firestore
                        setState(() {});
                      },
                      color: const Color(0xFF5CE65C),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: minItemCount,
                        itemBuilder: (context, index) {
                          Widget itemWidget;
                          if (index < displayProducts.length) {
                            final product = displayProducts[index];
                            itemWidget = _buildCatalogItem(product, index);
                          } else {
                            itemWidget = _buildEmptyItem(index);
                          }

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey[100]!,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: itemWidget,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCatalogItem(Product product, int index) {
    final isEven = index % 2 == 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SparePartDetailsPage(productId: product.productId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[300]!,
              width: 1.0,
            ),
            right: isEven
              ? BorderSide(
                  color: Colors.grey[300]!,
                  width: 1.0,
                )
              : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 8.0, right: 8.0, bottom: 12.0, top: 10.0),
                  child: product.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
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
                                  strokeWidth: 2,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5CE65C)),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[500],
                                  size: 32,
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.build,
                            color: Colors.grey[500],
                            size: 32,
                          ),
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 36,
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.currency} ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Stock: ${product.stock}',
                          style: TextStyle(
                            color: product.stock >= product.stockThreshold ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product.warehouse,
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text('|', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                          const SizedBox(width: 14),
                          Text(
                            product.rack,
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text('|', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                          const SizedBox(width: 14),
                          Text(
                            product.section,
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildEmptyItem(int index) {
    final isEven = index % 2 == 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1.0,
          ),
          right: isEven
            ? BorderSide(
                color: Colors.grey[300]!,
                width: 1.0,
              )
            : BorderSide.none,
        ),
      ),
      child: Container(
        color: Colors.white,
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }
}
