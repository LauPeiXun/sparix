import 'package:flutter/material.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/data/repositories/order_repository.dart';
import 'update_receive_item_page.dart';
import 'order_receipt.dart';

class OrdersSummaryPage extends StatefulWidget {
  final String orderId;

  // （可选）覆盖数据：保留
  final Map<String, int>? overrideGoodByProductId;
  final Map<String, int>? overrideDamageByProductId;
  final List<int>? receiveQty;
  final List<int>? damageQty;

  const OrdersSummaryPage({
    super.key,
    required this.orderId,
    this.overrideGoodByProductId,
    this.overrideDamageByProductId,
    this.receiveQty,
    this.damageQty,
  });

  @override
  State<OrdersSummaryPage> createState() => _OrdersSummaryPageState();
}

class _OrdersSummaryPageState extends State<OrdersSummaryPage> {
  final repo = OrderRepository();

  @override
  Widget build(BuildContext context) {
    final id = widget.orderId.trim();
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
              child:
              Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red)),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vm = snap.data!;

          // 显示用数量：优先 productId 覆盖 → 再 index 覆盖 → 否则数据库值
          int goodAt(int i) {
            final it = vm.items[i];
            final byId = widget.overrideGoodByProductId?[it.productId];
            if (byId != null) return byId;
            if (widget.receiveQty != null && i < widget.receiveQty!.length) {
              return widget.receiveQty![i];
            }
            return it.goodQty;
          }

          int damageAt(int i) {
            final it = vm.items[i];
            final byId = widget.overrideDamageByProductId?[it.productId];
            if (byId != null) return byId;
            if (widget.damageQty != null && i < widget.damageQty!.length) {
              return widget.damageQty![i];
            }
            return it.damageQty;
          }

          final totalReceive =
          List.generate(vm.items.length, goodAt).fold<int>(0, (s, v) => s + v);
          final totalReturned =
          List.generate(vm.items.length, damageAt).fold<int>(0, (s, v) => s + v);

          return Column(
            children: [
              // 顶部
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Text('Orders',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),

              // 白卡 + 订单号 + 列表
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Text('#${vm.code}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    fontSize: 14)),
                          ),
                          ...List.generate(vm.items.length * 2 - 1, (idx) {
                            if (idx.isOdd) {
                              return const Divider(height: 1, color: Color(0xFFEAEAEA));
                            }
                            final i = idx ~/ 2;
                            final it = vm.items[i];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UpdateReceiveItemPage(
                                      orderId: vm.orderId,
                                      initialIndex: i,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _thumb(it.imageUrl),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text((i + 1).toString().padLeft(2, '0'),
                                                  style: const TextStyle(
                                                      color: Color(0xFF3D73FF),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(it.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 15)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          _infoRow(
                                              'Price',
                                              it.unitPrice > 0
                                                  ? 'RM ${it.unitPrice.toStringAsFixed(2)}'
                                                  : '—'),
                                          const SizedBox(height: 6),
                                          _infoRow('Total', '${it.orderedQty}'),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              _pill('Receive',
                                                  bg: const Color(0xFFE8F5E8),
                                                  fg: const Color(0xFF2E7D32)),
                                              const SizedBox(width: 8),
                                              Text('${goodAt(i)}',
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700)),
                                              const SizedBox(width: 24),
                                              _pill('Returned',
                                                  bg: const Color(0xFFFFEBEE),
                                                  fg: const Color(0xFFD32F2F)),
                                              const SizedBox(width: 8),
                                              Text('${damageAt(i)}',
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // 合计 + Submit
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x11000000)),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 14)),
                            ),
                            _totalPill('Receive', totalReceive,
                                bg: const Color(0xFFDFF7E5),
                                fg: const Color(0xFF1B7F4B)),
                            const SizedBox(width: 8),
                            _totalPill('Returned', totalReturned,
                                bg: const Color(0xFFFFE2E0),
                                fg: const Color(0xFF9B1C1C)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () async {
                            // ✨ 新的「美美」确认弹窗
                            final ok = await _showPrettyConfirmDialog(
                              context: context,
                              totalReceive: totalReceive,
                              totalReturned: totalReturned,
                              itemCount: vm.items.length,
                            );
                            if (ok != true) return;

                            // 把“界面上的最终值”按 productId 打包传给收据页
                            final Map<String, int> goodById = {};
                            final Map<String, int> badById = {};
                            for (int i = 0; i < vm.items.length; i++) {
                              final it = vm.items[i];
                              goodById[it.productId] = goodAt(i);
                              badById[it.productId] = damageAt(i);
                            }

                            if (!mounted) return;
                            Navigator.push(
                              // ignore: use_build_context_synchronously
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderReceiptPage(
                                  orderId: vm.orderId,
                                  overrideGoodByProductId: goodById,
                                  overrideDamageByProductId: badById,
                                ),
                              ),
                            );
                          },
                          child: const Text('Submit',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ),
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

  // 小组件
  Widget _thumb(String url) {
    final child = url.isNotEmpty
        ? Image.network(url, width: 44, height: 44, fit: BoxFit.cover)
        : const Icon(Icons.handyman_outlined, color: Colors.grey, size: 22);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        color: const Color(0xFFF1F2F4),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Widget _infoRow(String k, String v) {
    return Row(
      children: [
        SizedBox(
            width: 50,
            child: Text(k, style: const TextStyle(color: Colors.black45, fontSize: 13))),
        const SizedBox(width: 6),
        Expanded(
          child: Text(v,
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _pill(String label, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child:
      Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12.5)),
    );
  }

  Widget _totalPill(String label, int value, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(width: 6),
          Text('$value', style: TextStyle(color: fg, fontSize: 12)),
        ],
      ),
    );
  }

  /// ---------- 这里是新的「美美」确认弹窗 ----------
  Future<bool?> _showPrettyConfirmDialog({
    required BuildContext context,
    required int totalReceive,
    required int totalReturned,
    required int itemCount,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              // 柔和卡片阴影
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 12),
                  blurRadius: 32,
                  spreadRadius: -12,
                  color: Color(0x33000000),
                ),
              ],
              color: Colors.white,
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部图标
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF4E5), Color(0xFFFFE9D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        offset: Offset(0, 6),
                        blurRadius: 16,
                        color: Color(0x40FF9800), // 25% 橙 = 0x40 alpha + FF9800
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.upload_rounded, size: 34, color: Color(0xFFFB8C00)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Submit this order?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Once submitted you can't edit receive/returned quantities.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.25),
                ),
                const SizedBox(height: 14),

                // 小胶囊统计
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _statChip(Icons.inventory_2_rounded, '$itemCount item(s)',
                        bg: const Color(0xFFF3F4F6), fg: Colors.black87),
                    _statChip(Icons.check_circle_rounded, 'Receive $totalReceive',
                        bg: const Color(0xFFDFF7E5), fg: const Color(0xFF1B7F4B)),
                    _statChip(Icons.highlight_off_rounded, 'Returned $totalReturned',
                        bg: const Color(0xFFFFE2E0), fg: const Color(0xFF9B1C1C)),
                  ],
                ),

                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black87,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.task_alt_rounded, size: 18),
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        label: const Text('Submit',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statChip(IconData icon, String text, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
