import 'package:flutter/material.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/data/repositories/order_repository.dart';
// ← 加上回列表页的 import（跟你项目其他地方一致的路径）
import 'package:sparix/presentation/screens/supplier_order/supplier_order_main_page.dart';

class DamageReceiptPage extends StatelessWidget {
  const DamageReceiptPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final repo = OrderRepository();
    final id = orderId.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: id.isEmpty
          ? const Center(child: Text('Invalid order id'))
          : StreamBuilder<OrderDetailVM>(
        stream: repo.watchOrderDetail(id),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final vm = snap.data!;
          final damaged = vm.items.where((e) => e.damageQty > 0).toList();
          final totalReturned =
          damaged.fold<int>(0, (s, it) => s + it.damageQty);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupplierOrderMainPage(),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Image.asset(
                          'assets/icons/package.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Returned Receipt • #${vm.code}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Returned',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        vm.supplierName,
                        style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '+60 ${vm.supplierContact}',
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // Header row
              const Divider(height: 1, color: Color(0x1A000000)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text('Items',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    Text('Returned Qty',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),

              if (damaged.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No returned items',
                        style: TextStyle(color: Colors.black54)),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    itemCount: damaged.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0x14000000)),
                    itemBuilder: (_, i) {
                      final it = damaged[i];
                      return _DamageRow(
                        imageUrl: it.imageUrl,
                        name: it.name,
                        unitPrice: it.unitPrice,
                        returnedQty: it.damageQty,
                      );
                    },
                  ),
                ),

              // Footer total
              if (damaged.isNotEmpty)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border:
                            Border.all(color: const Color(0x11000000)),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text('Total Returned',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE2E0),
                                  borderRadius:
                                  BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    const Text('Qty',
                                        style: TextStyle(
                                            color: Color(0xFF9B1C1C),
                                            fontWeight:
                                            FontWeight.w800)),
                                    const SizedBox(width: 6),
                                    Text('$totalReturned',
                                        style: const TextStyle(
                                            color: Color(0xFF9B1C1C))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Note: Returned items are not consider billed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 1),
    );
  }
}

class _DamageRow extends StatelessWidget {
  const _DamageRow({
    required this.imageUrl,
    required this.name,
    required this.unitPrice,
    required this.returnedQty,
  });

  final String imageUrl;
  final String name;
  final double unitPrice;
  final int returnedQty;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
    child:  Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44,
            height: 44,
            color: const Color(0xFFF1F2F4),
            alignment: Alignment.center,
            child: imageUrl.isEmpty
                ? const Icon(Icons.handyman_outlined, color: Colors.grey)
                : Image.network(
              imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Text('Price',
                      style: TextStyle(color: Colors.black45, fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    unitPrice > 0 ? 'RM ${unitPrice.toStringAsFixed(2)}' : '—',
                    style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Returned',
                  style: TextStyle(
                      color: Color(0xFF9B1C1C),
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // right qty
        Text('$returnedQty',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    ),
    );
  }
}
