import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/data/repositories/order_repository.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'orders_summary_page.dart';
import 'order_receipt.dart';

class UpdateReceiveItemPage extends StatefulWidget {
  final String orderId;
  final int? initialIndex;
  const UpdateReceiveItemPage({
    super.key,
    required this.orderId,
    this.initialIndex,
  });

  @override
  State<UpdateReceiveItemPage> createState() => _UpdateReceiveItemPageState();
}

class _UpdateReceiveItemPageState extends State<UpdateReceiveItemPage> {
  final repo = OrderRepository();
  final _fmt = DateFormat('dd/MM/yyyy');
  late PageController _pageCtrl;

  final Map<String, _QtyDraft> _drafts = {};
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: widget.initialIndex ?? 0);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  bool _isCompleted(String s) => s.trim().toLowerCase().startsWith('complet');

  @override
  Widget build(BuildContext context) {
    final id = widget.orderId.trim();

    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: Colors.white,
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

          // 若已完成 -> 直接跳收据
          if (!_redirected && _isCompleted(vm.status)) {
            _redirected = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderReceiptPage(orderId: vm.orderId),
                ),
              );
            });
            return const SizedBox.shrink();
          }

          // 初始化草稿
          for (final it in vm.items) {
            _drafts.putIfAbsent(
              it.productId,
                  () => _QtyDraft(good: it.goodQty, damage: it.damageQty),
            );
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Order ID ${vm.code}', // 用 code 展示
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${vm.code}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusPill(vm.status),
                  ],
                ),
                const SizedBox(height: 6),

                // 三行信息
                _kvRowWithDivider('Supplier', vm.supplierName,
                    showDivider: true),
                _kvRowWithDivider('Contact', '+60 ${vm.supplierContact}',
                    showDivider: true),
                _kvRowWithDivider('Date', _fmt.format(vm.date),
                    showDivider: false),

                const SizedBox(height: 20),

                SizedBox(
                  height: 420,
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageCtrl,
                          itemCount: vm.items.length,
                          itemBuilder: (_, i) {
                            final it = vm.items[i];
                            final d = _drafts[it.productId]!;
                            final remaining =
                                it.orderedQty - (d.good + d.damage);

                            return _itemCard(
                              name: it.name,
                              imageUrl: it.imageUrl,
                              orderedQty: it.orderedQty,
                              unitPrice: it.unitPrice,
                              good: d.good,
                              bad: d.damage,
                              remaining: remaining,
                              onGoodMinus: () => _updateQty(vm,
                                  it.productId,
                                  good: (d.good - 1)
                                      .clamp(0, it.orderedQty)),
                              onGoodPlus: () => _updateQty(vm,
                                  it.productId,
                                  good: (d.good + 1)
                                      .clamp(0, it.orderedQty)),
                              onBadMinus: () => _updateQty(vm,
                                  it.productId,
                                  damage: (d.damage - 1)
                                      .clamp(0, it.orderedQty)),
                              onBadPlus: () => _updateQty(vm,
                                  it.productId,
                                  damage: (d.damage + 1)
                                      .clamp(0, it.orderedQty)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      SmoothPageIndicator(
                        controller: _pageCtrl,
                        count: vm.items.length,
                        onDotClicked: (index) => _pageCtrl.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                        effect: const WormEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          spacing: 8,
                          activeDotColor: Colors.black87,
                          dotColor: Colors.black26,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final incompletes = _incompleteIndexes(vm);
                      if (incompletes.isNotEmpty) {
                        await _showPrettyIncompleteDialog(vm, incompletes);
                        return;
                      }

                      final goodById = <String, int>{};
                      final badById = <String, int>{};
                      for (final it in vm.items) {
                        final d = _drafts[it.productId]!;
                        goodById[it.productId] = d.good;
                        badById[it.productId] = d.damage;
                      }

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrdersSummaryPage(
                            orderId: vm.orderId, // 用 orderId 传参
                            overrideGoodByProductId: goodById,
                            overrideDamageByProductId: badById,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const SizedBox(height: 72),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 1),
    );
  }

  // —— 数量更新（本地 + 落库） —— //
  Future<void> _updateQty(
      OrderDetailVM vm,
      String productId, {
        int? good,
        int? damage,
      }) async {
    final cur = _drafts[productId]!;
    final g = good ?? cur.good;
    final d = damage ?? cur.damage;

    final item = vm.items.firstWhere((e) => e.productId == productId);
    if (g + d > item.orderedQty) return;

    setState(() {
      _drafts[productId] = _QtyDraft(good: g, damage: d);
    });

    await repo.updateItemQty(
      orderId: vm.orderId,
      productId: productId,
      goodQty: g,
      damageQty: d,
    );
  }

  // —— 校验 —— //
  List<int> _incompleteIndexes(OrderDetailVM vm) {
    final List<int> list = [];
    for (int i = 0; i < vm.items.length; i++) {
      final it = vm.items[i];
      final d = _drafts[it.productId]!;
      if ((d.good + d.damage) != it.orderedQty) list.add(i);
    }
    return list;
  }

  Future<void> _showPrettyIncompleteDialog(
      OrderDetailVM vm,
      List<int> incompletes,
      ) async {
    final totalRemaining = incompletes.fold<int>(0, (sum, idx) {
      final it = vm.items[idx];
      final d = _drafts[it.productId]!;
      return sum + (it.orderedQty - d.good - d.damage);
    });

    return showDialog<void>(
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
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 12),
                  blurRadius: 32,
                  spreadRadius: -12,
                  color: Color(0x33000000), // 20% 黑色阴影 (0x33 = 51 ≈ 0.20 * 255)
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        color: Color(0x40FF9800),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.priority_high_rounded,
                        size: 34, color: Color(0xFFFB8C00)),
                  ),
                ),

                const SizedBox(height: 14),
                const Text(
                  "Haven’t completed",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  "You still have $totalRemaining unit(s) unassigned. "
                      "Please finish before confirming.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, height: 1.25),
                ),
                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _statChip(Icons.inventory_2_rounded,
                        '${incompletes.length} item(s)',
                        bg: const Color(0xFFF3F4F6), fg: Colors.black87),
                    _statChip(Icons.hourglass_bottom_rounded,
                        'Remaining $totalRemaining',
                        bg: const Color(0xFFFFE2E0), fg: const Color(0xFF9B1C1C)),
                  ],
                ),

                const SizedBox(height: 14),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: incompletes.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFEAEAEA)),
                    itemBuilder: (_, i) {
                      final idx = incompletes[i];
                      final it = vm.items[idx];
                      final d = _drafts[it.productId]!;
                      final rem = it.orderedQty - d.good - d.damage;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F2F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, size: 20),
                        ),
                        title: Text(
                          it.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        trailing: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            Navigator.of(context).pop();
                            _pageCtrl.animateToPage(
                              idx,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Remaining ',
                                  style: TextStyle(
                                      color: Color(0xFF9B1C1C), fontSize: 12)),
                              // rem 数字
                            ],
                          ),
                        ),
                        subtitle: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 0),
                            const SizedBox(width: 0),
                            const Text(''),
                            Text(
                              'Remaining: $rem',
                              style: const TextStyle(
                                  color: Color(0xFF9B1C1C),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          _pageCtrl.animateToPage(
                            idx,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (incompletes.isNotEmpty) {
                            _pageCtrl.animateToPage(
                              incompletes.first,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        icon: const Icon(Icons.navigation_rounded),
                        label: const Text('Review item'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black87,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        label: const Text('OK',
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

// 复用的小胶囊
  Widget _statChip(IconData icon, String text,
      {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }


  // —— UI 子块 —— //
  Widget _itemCard({
    required String name,
    required String imageUrl,
    required int orderedQty,
    required double unitPrice,
    required int good,
    required int bad,
    required int remaining,
    required VoidCallback onGoodMinus,
    required VoidCallback onGoodPlus,
    required VoidCallback onBadMinus,
    required VoidCallback onBadPlus,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 15,
            color: Colors.grey.shade300,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: imageUrl.isEmpty
                ? const Center(
              child: Icon(
                Icons.precision_manufacturing_outlined,
                size: 48,
                color: Colors.black54,
              ),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 14),

          Text(name,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Order Quantity : ',
                  style: TextStyle(color: Colors.black54)),
              Text('$orderedQty',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),

          _qtyRow(
            label: 'Good items',
            labelColor: const Color(0xFF19A464),
            value: good,
            onMinus: onGoodMinus,
            onPlus: () {
              if (remaining > 0) onGoodPlus();
            },
          ),
          const SizedBox(height: 20),

          _qtyRow(
            label: 'Damage Items',
            labelColor: const Color(0xFFDA3A3A),
            value: bad,
            onMinus: onBadMinus,
            onPlus: () {
              if (remaining > 0) onBadPlus();
            },
          ),

          const Spacer(),
          const Divider(),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining: $remaining',
                style: TextStyle(
                  color: remaining == 0
                      ? Colors.black54
                      : const Color(0xFFDA3A3A),
                  fontWeight: FontWeight.w300,
                ),
              ),
              if (unitPrice > 0)
                Text(
                  'RM ${unitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyRow({
    required String label,
    required Color labelColor,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: TextStyle(color: labelColor, fontWeight: FontWeight.w600)),
        ),
        const Spacer(),
        _circleBtn(Icons.remove, onMinus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$value',
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        _circleBtn(Icons.add, onPlus),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _kvRowWithDivider(String k, String v, {bool showDivider = true}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(k, style: const TextStyle(color: Colors.black54)),
              ),
              Expanded(
                child: Text(v,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0x1A000000)),
      ],
    );
  }

  Widget _statusPill(String status) {
    Color bg;
    Color textColor;
    String label = status;

    if (status.toLowerCase().startsWith('complet')) {
      bg = const Color(0xFFDFF7E5);
      textColor = const Color(0xFF1B7F4B);
      label = 'Completed';
    } else if (status.toLowerCase() == 'pending') {
      bg = const Color(0xFFFFF3BF);
      textColor = const Color(0xFFAD8B00);
      label = 'Pending';
    } else if (status.toLowerCase() == 'returned') {
      bg = const Color(0xFFFFE2E0);
      textColor = const Color(0xFF9B1C1C);
      label = 'Returned';
    } else {
      bg = Colors.grey.shade200;
      textColor = Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}

class _QtyDraft {
  final int good;
  final int damage;
  const _QtyDraft({required this.good, required this.damage});
}
