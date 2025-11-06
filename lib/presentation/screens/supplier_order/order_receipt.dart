import 'package:flutter/material.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/data/repositories/order_repository.dart';
import 'package:sparix/presentation/screens/supplier_order/supplier_order_main_page.dart';
import 'damage_receipt_page.dart';

class OrderReceiptPage extends StatefulWidget {
  final String orderId;

  // 当从 Summary “Submit” 后跳来时传 true，只想这一次显示“提交成功”弹窗
  final bool showSubmitSuccess;

  // 覆盖（Summary 页面带过来的最终数值）
  final Map<String, int>? overrideGoodByProductId;
  final Map<String, int>? overrideDamageByProductId;

  const OrderReceiptPage({
    super.key,
    required this.orderId,
    this.overrideGoodByProductId,
    this.overrideDamageByProductId,
    this.showSubmitSuccess = false,
  });

  @override
  State<OrderReceiptPage> createState() => _OrderReceiptPageState();
}

class _OrderReceiptPageState extends State<OrderReceiptPage> {
  final repo = OrderRepository();

  // 只在本次展示中做一次 finalize；成功/失败弹窗也只弹一次
  bool _finalizedOnce = false;
  bool _successShown = false;

  bool _isCompleted(String s) => s.trim().toLowerCase().startsWith('complet');

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
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vm = snap.data!;

          // 只在“提交后第一次打开”且订单已完成时弹一次成功
          _maybeShowSubmitSuccessOnce(vm);

          // 若收到覆盖值（从 Summary 来），在这里做一次写库并弹窗
          _finalizeIfNeeded(vm);

          int goodAt(int i) {
            final it = vm.items[i];
            return widget.overrideGoodByProductId?[it.productId] ??
                it.goodQty;
          }

          int badAt(int i) {
            final it = vm.items[i];
            return widget.overrideDamageByProductId?[it.productId] ??
                it.damageQty;
          }

          final totalPrice = List.generate(vm.items.length, (i) {
            final it = vm.items[i];
            return it.unitPrice * goodAt(i);
          }).fold<double>(0.0, (s, v) => s + v);

          final totalReturned = List.generate(vm.items.length, badAt)
              .fold<int>(0, (s, v) => s + v);

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
                            builder: (_) =>
                            const SupplierOrderMainPage(),
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
                        'Order ID #${vm.code}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _statusPill(vm.status),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Supplier / Contact（中间加间距）
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
                    const SizedBox(width: 10),
                    Text(
                      '+60 ${vm.supplierContact}',
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // table header
              const Divider(height: 1, color: Color(0x1A000000)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Items',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    Text(
                      'Order Quantity',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: vm.items.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, color: Color(0x14000000)),
                  itemBuilder: (_, i) {
                    final it = vm.items[i];
                    final receive = goodAt(i);
                    final returned = badAt(i);
                    return _ItemRow(
                      imageUrl: it.imageUrl,
                      name: it.name,
                      unitPrice: it.unitPrice,
                      orderedQty: it.orderedQty,
                      receiveQty: receive,
                      returnedQty: returned,
                    );
                  },
                ),
              ),

              // total & damage-entry
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Total Price',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800)),
                          ),
                          Text(
                            'RM ${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (totalReturned > 0)
                        TextButton.icon(
                          icon: const Icon(Icons.report_rounded),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFD32F2F),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DamageReceiptPage(
                                    orderId: vm.orderId),
                              ),
                            );
                          },
                          label:
                          const Text('View Returned Receipt'),
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

  /// 只在“提交后第一次打开收据页”且订单已是 completed 的情况下弹一次成功提示
  void _maybeShowSubmitSuccessOnce(OrderDetailVM vm) {
    if (_successShown) return;
    if (!widget.showSubmitSuccess) return;
    if (!_isCompleted(vm.status)) return;

    _successShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showResultDialog(
        success: true,
        title: 'Order submitted',
        message: 'Order saved to database successfully.',
      );
    });
  }

  /// 收到覆盖值时才写库；若订单早已完成或没有覆盖值，则不写库。
  Future<void> _finalizeIfNeeded(OrderDetailVM vm) async {
    if (_finalizedOnce) return;

    final hasOverrides =
        (widget.overrideGoodByProductId?.isNotEmpty ?? false) ||
            (widget.overrideDamageByProductId?.isNotEmpty ?? false);
    final alreadyCompleted = _isCompleted(vm.status);

    if (!hasOverrides || alreadyCompleted) return;

    _finalizedOnce = true;

    int finalGoodAt(int i) {
      final it = vm.items[i];
      return widget.overrideGoodByProductId?[it.productId] ?? it.goodQty;
    }

    int finalBadAt(int i) {
      final it = vm.items[i];
      return widget.overrideDamageByProductId?[it.productId] ?? it.damageQty;
    }

    final totalReceive =
    List.generate(vm.items.length, finalGoodAt).fold<int>(0, (s, v) => s + v);
    final totalReturned =
    List.generate(vm.items.length, finalBadAt).fold<int>(0, (s, v) => s + v);
    final totalPrice = List.generate(vm.items.length, (i) {
      final it = vm.items[i];
      return it.unitPrice * finalGoodAt(i);
    }).fold<double>(0.0, (s, v) => s + v);

    try {
      await repo.finalizeOrderAndOverwriteItems(
        orderId: vm.orderId,
        currentItems: vm.items,
        goodById: widget.overrideGoodByProductId,
        damageById: widget.overrideDamageByProductId,
        status: 'completed',
        totalReceive: totalReceive,
        totalReturned: totalReturned,
        totalPrice: totalPrice,
        completedAt: DateTime.now(),
      );

      if (mounted && widget.showSubmitSuccess && !_successShown) {
        _successShown = true;
        await _showResultDialog(
          success: true,
          title: 'Order submitted',
          message: 'Order saved to database successfully.',
        );
      }
    } catch (e) {
      if (mounted && !_successShown) {
        _successShown = true;
        await _showResultDialog(
          success: false,
          title: 'Failed to save',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _showResultDialog({
    required bool success,
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        final Color grad1 =
        success ? const Color(0xFFE8FFF3) : const Color(0xFFFFF4E5);
        final Color grad2 =
        success ? const Color(0xFFDFF7E5) : const Color(0xFFFFE9D2);
        final Color iconColor =
        success ? const Color(0xFF1B7F4B) : const Color(0xFFFB8C00);
        final IconData icon =
        success ? Icons.task_alt_rounded : Icons.error_rounded;

        return Dialog(
          elevation: 0,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 12),
                  blurRadius: 32,
                  spreadRadius: -12,
                  color: Color(0x33000000),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [grad1, grad2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 6),
                        blurRadius: 16,
                        color: iconColor.withAlpha(0x40), // 25% 透明度（0x40 = 64）
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(icon, size: 34, color: iconColor),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, height: 1.25),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('OK',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusPill(String status) {
    final s = status.toLowerCase();
    Color bg;
    String label;
    if (s == 'completed' || s == 'complete') {
      bg = const Color(0xFF22C55E);
      label = 'Completed';
    } else if (s == 'returned') {
      bg = const Color(0xFFE11D48);
      label = 'Returned';
    } else {
      bg = const Color(0xFFF59E0B);
      label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.imageUrl,
    required this.name,
    required this.unitPrice,
    required this.orderedQty,
    required this.receiveQty,
    required this.returnedQty,
  });

  final String imageUrl;
  final String name;
  final double unitPrice;
  final int orderedQty;
  final int receiveQty;
  final int returnedQty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
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

          // middle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      'Price',
                      style: TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      unitPrice > 0 ? 'RM ${unitPrice.toStringAsFixed(2)}' : '—',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _pill(
                      'Receive',
                      bg: const Color(0xFFE8F5E8),
                      fg: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$receiveQty',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 24),
                    _pill(
                      'Returned',
                      bg: const Color(0xFFFFEBEE),
                      fg: const Color(0xFFD32F2F),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$returnedQty',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // right qty
          Text(
            '$orderedQty',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
        TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
