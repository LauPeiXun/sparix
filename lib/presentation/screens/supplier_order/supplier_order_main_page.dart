import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/data/repositories/order_repository.dart';

import 'update_receive_item_page.dart';
import 'damage_receipt_page.dart';

class SupplierOrderMainPage extends StatefulWidget {
  const SupplierOrderMainPage({super.key});

  @override
  State<SupplierOrderMainPage> createState() => _SupplierOrderMainPageState();
}

class _SupplierOrderMainPageState extends State<SupplierOrderMainPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final _repo = OrderRepository();
  final _fmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18,vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ORDER LIST',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search for....',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<OrderListTileVM>>(
                stream: _repo.watchOrders(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                        child: Text('Error: ${snap.error}',
                            style: const TextStyle(color: Colors.red)));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final all = snap.data!;
                  final q = _searchCtrl.text.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? all
                      : all.where((o) {
                    return o.code.toLowerCase().contains(q) ||
                        o.supplierName.toLowerCase().contains(q) ||
                        o.supplierContact.toString().contains(q);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No orders found',
                          style: TextStyle(color: Colors.black54)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final o = filtered[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding:
                        const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                              spreadRadius: -2,
                            ),
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('#${o.code}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                          fontWeight:
                                          FontWeight.w700)),
                                ),
                                _statusChip(o.status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _kv(context, 'Supplier', o.supplierName),
                            const Divider(height: 3),
                            const SizedBox(height: 6),
                            _kv(context, 'Contact',
                                '+60 ${o.supplierContact}'),
                            const SizedBox(height: 6),
                            const Divider(height: 3),
                            _kv(context, 'Date', _fmt.format(o.date)),
                            const SizedBox(height: 6),

                            // Buttons
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    if (o.orderId.trim().isEmpty) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UpdateReceiveItemPage(
                                              orderId: o.orderId,
                                            ),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: const StadiumBorder(),
                                    side: const BorderSide(
                                        color: Colors.black87),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                  ),
                                  child: const Text('Details'),
                                ),
                                const SizedBox(width: 8),
                                StreamBuilder<
                                    DocumentSnapshot<
                                        Map<String, dynamic>>>(
                                  stream: FirebaseFirestore.instance
                                      .collection('order_list')
                                      .doc(o.orderId)
                                      .snapshots(),
                                  builder: (context, s) {
                                    if (!s.hasData) {
                                      return const SizedBox.shrink();
                                    }
                                    final data = s.data!.data() ?? {};
                                    final status = (data['status'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                    final totalReturnedRaw =
                                    data['totalReturned'];
                                    final totalReturned =
                                    (totalReturnedRaw is int)
                                        ? totalReturnedRaw
                                        : int.tryParse(
                                        '$totalReturnedRaw') ??
                                        0;

                                    final canShow = status
                                        .startsWith('completed') &&
                                        totalReturned > 0;
                                    if (!canShow) {
                                      return const SizedBox.shrink();
                                    }
                                    return TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DamageReceiptPage(
                                                    orderId: o.orderId),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                        const Color(0xFFD32F2F),
                                        shape: const StadiumBorder(),
                                      ),
                                      icon: const Icon(
                                          Icons.report_rounded),
                                      label:
                                      const Text('Damage receipt'),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 1),
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Row(
    children: [
      SizedBox(
        width: 70,
        child: Text(k,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black54)),
      ),
      Expanded(
        child: Text(v,
            textAlign: TextAlign.right,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
      ),
    ],
  );

  Widget _statusChip(String status) {
    Color bg, fg;
    String label;
    switch (status.toLowerCase()) {
      case 'completed':
        bg = const Color(0xFFDFF7E5);
        fg = const Color(0xFF1B7F4B);
        label = 'Completed';
        break;
      case 'returned':
        bg = const Color(0xFFFFE2E0);
        fg = const Color(0xFF9B1C1C);
        label = 'Returned';
        break;
      default:
        bg = const Color(0xFFFFF6CC);
        fg = const Color(0xFFAD8B00);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
