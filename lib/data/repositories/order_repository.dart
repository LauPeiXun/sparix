import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_list.dart';
import '../models/supplier.dart';
import 'product_repository.dart';


class OrderListTileVM {
  final String orderId;
  final String code;
  final String status;
  final DateTime date;
  final String supplierName;
  final int supplierContact; // int

  OrderListTileVM({
    required this.orderId,
    required this.code,
    required this.status,
    required this.date,
    required this.supplierName,
    required this.supplierContact,
  });
}

class OrderDetailItemVM {
  final String productId;
  final String name;
  final String imageUrl;
  final double unitPrice;
  final int orderedQty;
  final int goodQty;
  final int damageQty;

  int get remaining => orderedQty - (goodQty + damageQty);
  double get lineTotal => unitPrice * goodQty;

  OrderDetailItemVM({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.orderedQty,
    required this.goodQty,
    required this.damageQty,
  });
}

class OrderDetailVM {
  /// Firestore 文档 id（用于查询/跳转）
  final String orderId;

  /// 对外显示的订单号（原来的 orderCode）
  final String code;

  final String status;
  final DateTime date;
  final String supplierName;
  final int supplierContact; // int
  final List<OrderDetailItemVM> items;

  // ignore: avoid_types_as_parameter_names
  double get totalPrice => items.fold(0.0, (sum, it) => sum + it.lineTotal);

  OrderDetailVM({
    required this.orderId,
    required this.code,
    required this.status,
    required this.date,
    required this.supplierName,
    required this.supplierContact,
    required this.items,
  });
}

/// ========== REPOSITORY ==========

class OrderRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ProductRepository _productRepository = ProductRepository();

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('order_list');

  /* ------------------ 列表：拼 supplier ------------------ */
  Stream<List<OrderListTileVM>> watchOrders() {
    return _orders
        .orderBy('orderDate', descending: true)
        .snapshots()
        .asyncMap((qs) async {
      final Map<String, Supplier> supCache = {};
      final futures = qs.docs.map((doc) async {
        final order = OrderDoc.fromSnap(doc);

        Supplier? sup;
        final sid = order.supplierId.trim();
        if (sid.isNotEmpty) {
          if (supCache.containsKey(sid)) {
            sup = supCache[sid];
          } else {
            final s = await _db.collection('supplier').doc(sid).get();
            if (s.exists) {
              sup = Supplier.fromSnap(s);
              supCache[sid] = sup;
            }
          }
        }

        return OrderListTileVM(
          orderId: order.id,            // 文档 id
          code: order.orderCode,        // 显示编号
          status: order.status,
          date: order.orderDate,
          supplierName: sup?.supplierName ?? '(No supplier)',
          supplierContact: sup?.contact ?? 0, // int
        );
      }).toList();

      return Future.wait(futures);
    });
  }

  /* ------------------ 详情：拼 supplier + spare_part ------------------ */
  Stream<OrderDetailVM> watchOrderDetail(String orderId) {
    final oid = orderId.trim();
    if (oid.isEmpty) {
      return Stream.error('Invalid orderId (empty)');
    }

    final docRef = _orders.doc(oid);
    return docRef.snapshots().asyncMap((doc) async {
      if (!doc.exists) throw 'Order not found: $oid';
      final order = OrderDoc.fromSnap(doc);

      // supplier
      Supplier? sup;
      final sid = order.supplierId.trim();
      if (sid.isNotEmpty) {
        final s = await _db.collection('supplier').doc(sid).get();
        if (s.exists) sup = Supplier.fromSnap(s);
      }

      // spare_part 批量 whereIn（每批 <=10）
      final ids = order.items
          .map((e) => e.productId.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final Map<String, Map<String, dynamic>> productMap = {};
      for (var i = 0; i < ids.length; i += 10) {
        final batch =
        ids.sublist(i, (i + 10 > ids.length) ? ids.length : i + 10);
        final qs = await _db
            .collection('spare_part')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final d in qs.docs) {
          productMap[d.id] = d.data();
        }
      }

      double asDouble(dynamic v) {
        if (v is num) return v.toDouble();
        return double.tryParse((v ?? '').toString()) ?? 0;
      }

      final itemVMs = order.items.map((raw) {
        final p = productMap[raw.productId] ?? {};
        final name = (p['name'] ?? '').toString();
        final image = (p['imageUrl'] ?? '').toString();
        final price = asDouble(p['salesAmount'] ?? p['price']); // Updated to use salesAmount first
        return OrderDetailItemVM(
          productId: raw.productId,
          name: name.isEmpty ? '(Product missing)' : name,
          imageUrl: image,
          unitPrice: price,
          orderedQty: raw.orderedQty,
          goodQty: raw.goodQty,
          damageQty: raw.damageQty,
        );
      }).toList();

      return OrderDetailVM(
        orderId: order.id,           // 文档 id
        code: order.orderCode,       // 显示编号
        status: order.status,
        date: order.orderDate,
        supplierName: sup?.supplierName ?? '(No supplier)',
        supplierContact: sup?.contact ?? 0, // int
        items: itemVMs,
      );
    });
  }

  /* -------- 更新某 item 的 goodQty / damageQty（含保护） -------- */
  Future<void> updateItemQty({
    required String orderId,
    required String productId,
    required int goodQty,
    required int damageQty,
  }) async {
    final ref = _orders.doc(orderId.trim());
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Order not found');

    final d = snap.data() as Map<String, dynamic>;
    final list = List<Map<String, dynamic>>.from(d['items'] ?? []);
    final idx = list.indexWhere((e) =>
    ((e['productID'] ?? e['productId'] ?? '').toString().trim()) ==
        productId.trim());
    if (idx == -1) {
      throw Exception('Item not found for productId=$productId');
    }

    int asInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse((v ?? '').toString()) ?? 0;
    }

    final ordered = asInt(list[idx]['orderedQty'] ?? list[idx]['orderQty']);
    if (goodQty + damageQty > ordered) {
      throw Exception('goodQty + damageQty cannot exceed orderedQty');
    }

    list[idx] = {
      ...list[idx],
      'productID': productId, // 你的库里字段是 productID
      'orderedQty': ordered,
      'goodQty': goodQty,
      'damageQty': damageQty,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await ref.update({'items': list, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// 一次性覆盖 items + 写入合计 + 标记完成 + 更新库存
  Future<void> finalizeOrderAndOverwriteItems({
    required String orderId,
    required List<OrderDetailItemVM> currentItems,
    Map<String, int>? goodById, // productId -> good
    Map<String, int>? damageById, // productId -> damage
    required String status, // 'completed'
    required int totalReceive,
    required int totalReturned,
    required double totalPrice,
    required DateTime completedAt,
  }) async {
    final ref = _orders.doc(orderId.trim());

    // 用覆盖值生成"最终 items 数组"
    final newItems = currentItems.map((it) {
      final g = (goodById?[it.productId]) ?? it.goodQty;
      final d = (damageById?[it.productId]) ?? it.damageQty;
      return {
        'productID': it.productId, // ✅ 你库里字段是 productID
        'orderedQty': it.orderedQty,
        'goodQty': g,
        'damageQty': d,
      };
    }).toList();

    // Update order status first
    await ref.update({
      'items': newItems,
      'itemCount': newItems.length,
      'status': status,
      'totalReceive': totalReceive,
      'totalReturned': totalReturned,
      'totalPrice': totalPrice,
      'completedAt': Timestamp.fromDate(completedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // If order is completed, update spare part stock quantities
    if (status.toLowerCase() == 'completed') {
      await _updateSparePartStockAfterOrderCompletion(currentItems, goodById);
    }
  }

  /// Update spare part stock after order completion
  Future<void> _updateSparePartStockAfterOrderCompletion(
    List<OrderDetailItemVM> items,
    Map<String, int>? goodById,
  ) async {
    try {
      print('🔄 Updating spare part stock after order completion...');
      
      // Create map of productId -> good quantity received
      final Map<String, int> stockUpdates = {};
      
      for (final item in items) {
        final goodQty = (goodById?[item.productId]) ?? item.goodQty;
        if (goodQty > 0) {
          stockUpdates[item.productId] = goodQty;
          print('📦 Will add $goodQty units to stock for product ${item.productId}');
        }
      }
      
      if (stockUpdates.isNotEmpty) {
        await _productRepository.updateMultipleProductStocks(stockUpdates);
        print('✅ Successfully updated spare part stock for ${stockUpdates.length} products');
      } else {
        print('ℹ️ No stock updates needed - no good quantities received');
      }
      
    } catch (e) {
      print('❌ Error updating spare part stock: $e');
      // Don't rethrow to avoid failing the entire order completion
    }
  }

  Future<void> finalizeOrder({
    required String orderId,
    required String status, // e.g. 'completed'
    required int totalReceive,
    required int totalReturned,
    required double totalPrice,
    required DateTime completedAt,
  }) async {
    // Update order status
    await _orders.doc(orderId.trim()).update({
      'status': status,
      'totalReceive': totalReceive,
      'totalReturned': totalReturned,
      'totalPrice': totalPrice,
      'completedAt': Timestamp.fromDate(completedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // If order is completed, update spare part stock quantities
    if (status.toLowerCase() == 'completed') {
      await _updateSparePartStockFromOrder(orderId.trim());
    }
  }

  /// Update spare part stock from order items
  Future<void> _updateSparePartStockFromOrder(String orderId) async {
    try {
      print('🔄 Updating spare part stock from completed order: $orderId');
      
      // Get the order document to access items
      final orderDoc = await _orders.doc(orderId).get();
      if (!orderDoc.exists) {
        print('❌ Order document not found: $orderId');
        return;
      }
      
      final orderData = orderDoc.data() as Map<String, dynamic>;
      final itemsList = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
      
      final Map<String, int> stockUpdates = {};
      
      for (final item in itemsList) {
        final productId = (item['productID'] ?? item['productId'] ?? '').toString().trim();
        final goodQty = (item['goodQty'] ?? 0) as int;
        
        if (productId.isNotEmpty && goodQty > 0) {
          stockUpdates[productId] = goodQty;
          print('📦 Will add $goodQty units to stock for product $productId');
        }
      }
      
      if (stockUpdates.isNotEmpty) {
        await _productRepository.updateMultipleProductStocks(stockUpdates);
        print('✅ Successfully updated spare part stock for ${stockUpdates.length} products');
      } else {
        print('ℹ️ No stock updates needed - no good quantities received');
      }
      
    } catch (e) {
      print('❌ Error updating spare part stock from order: $e');
      // Don't rethrow to avoid failing the entire order completion
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _orders.doc(orderId.trim()).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // If order status is changed to completed, update spare part stock
    if (status.toLowerCase() == 'completed') {
      await _updateSparePartStockFromOrder(orderId.trim());
    }
  }

  Future<void> updateOrderTotals({
    required String orderId,
    required int totalReceive,
    required int totalReturned,
    required double totalPrice,
    DateTime? completedAt,
  }) async {
    final data = <String, dynamic>{
      'totalReceive': totalReceive,
      'totalReturned': totalReturned,
      'totalPrice': totalPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (completedAt != null) {
      data['completedAt'] = Timestamp.fromDate(completedAt);
    }
    await _orders.doc(orderId.trim()).update(data);
  }
}
