import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part_request.dart';
import 'product_repository.dart';
import '../../core/services/firebase_firestore_service.dart';

class PartRequestRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final ProductRepository _productRepository = ProductRepository();
  static const String partRequestCol = 'part_request';
  static const String workshopsCol = 'workshop';  
  static const String itemsCol = 'sparePart';

  Stream<List<PartRequest>> getPartRequestsStream() {
    return _firestoreService
        .streamCollection(
          collection: partRequestCol,
          queryBuilder: (query) => query.orderBy('orderDate', descending: true),
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => PartRequest.fromFirestore(doc))
            .toList());
  }

  Stream<List<PartRequest>> getPartRequestsByStatus(String status) {
    return _firestoreService
        .streamCollection(
          collection: partRequestCol,
          queryBuilder: (query) => query.where('status', isEqualTo: status.toLowerCase()),
        )
        .map((snapshot) {
      List<PartRequest> requests = snapshot.docs
          .map((doc) => PartRequest.fromFirestore(doc))
          .toList();
      requests.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      return requests;
    });
  }

  Stream<List<PartRequest>> getFilteredRequestsStream(String status) {
    return _firestoreService
        .streamCollection(collection: partRequestCol)
        .map((snapshot) {
      List<PartRequest> allRequests = snapshot.docs
          .map((doc) => PartRequest.fromFirestore(doc))
          .toList();

      List<PartRequest> filtered = allRequests
          .where((request) => request.status.toLowerCase() == status.toLowerCase())
          .toList();

      filtered.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      return filtered;
    });
  }

  Future<PartRequest?> getPartRequestById(String requestId) async {
    try {
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = await _firestoreService
          .getDocumentsWhereEqualTo(
            collectionPath: partRequestCol,
            fieldName: 'requestId',
            value: requestId,
          );

      if (docs.isNotEmpty) {
        DocumentSnapshot doc = docs.first;
        // ignore: unused_local_variable
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return PartRequest.fromFirestore(doc);
      } else {
        print('No documents found with requestId: $requestId');
      }
      return null;
    } catch (e) {
      print('Error getting part request: $e');
      return null;
    }
  }

  Future<Workshop?> getWorkshopById(String workshopDocId) async {
    try {
      DocumentSnapshot doc = await _firestoreService
          .getDocument(
            collection: workshopsCol,
            docId: workshopDocId,
          );

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return Workshop.fromFirestore(doc);
        }
      } else {
        DocumentSnapshot altDoc = await _firestoreService
            .getDocument(
              collection: 'workshops',
              docId: workshopDocId,
            );
        if (altDoc.exists && altDoc.data() != null) {
          return Workshop.fromFirestore(altDoc);
        }
      }
      return null;
    } catch (e) {
      print('Error getting workshop: $e');
      return null;
    }
  }

  Future<Workshop?> getWorkshopByShopId(String shopId) async {
    try {
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = await _firestoreService
          .getDocumentsWhereEqualTo(
            collectionPath: workshopsCol,
            fieldName: 'shopId',
            value: shopId,
          );

      if (docs.isNotEmpty) {
        return Workshop.fromFirestore(docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<ItemDetail?> getItemDetail(String itemDocId) async {
    try {
      DocumentSnapshot doc = await _firestoreService
          .getDocument(
            collection: itemsCol,
            docId: itemDocId,
          );

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          print('Item data: ${data['title'] ?? data['name'] ?? 'Unknown'}');
          return ItemDetail.fromFirestore(doc);
        }
      } else {
        List<String> altCollections = ['items', 'item', 'spare_part', 'spareParts'];
        for (String altCol in altCollections) {
          DocumentSnapshot altDoc = await _firestoreService
              .getDocument(
                collection: altCol,
                docId: itemDocId,
              );
          if (altDoc.exists && altDoc.data() != null) {
            return ItemDetail.fromFirestore(altDoc);
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<double> calculateTotalPrice(List<ItemRequest> itemList) async {
    double total = 0.0;
    for (ItemRequest itemRequest in itemList) {
      ItemDetail? itemDetail = await getItemDetail(itemRequest.itemDocId);
      if (itemDetail != null) {
        total += itemDetail.unitPrice * itemRequest.quantity;
      }
    }
    return total;
  }

  //get total price
  Future<double> getTotalPriceForRequest(PartRequest request) async {
    return await calculateTotalPrice(request.itemList);
  }

  Future<bool> updatePartRequestStatus(String documentId, String newStatus) async {
    try {
      String statusColor = _getStatusColor(newStatus);

      await _firestoreService
          .updateDocument(
            collection: partRequestCol,
            docId: documentId,
            data: {
              'status': newStatus.toLowerCase(),
              'statusColor': statusColor,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );

      if (newStatus.toLowerCase() == 'approved') {
        await _deductStockForApprovedRequest(documentId);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  //deduct spare part qty
  Future<void> _deductStockForApprovedRequest(String documentId) async {
    try {
      final requestDoc = await _firestoreService
          .getDocument(
            collection: partRequestCol,
            docId: documentId,
          );
      
      if (!requestDoc.exists) {
        return;
      }
      
      final PartRequest request = PartRequest.fromFirestore(requestDoc);
      final Map<String, int> stockDeductions = {};

      for (final itemRequest in request.itemList) {
        final itemDocId = itemRequest.itemDocId.trim();
        final quantity = itemRequest.quantity;
        
        if (itemDocId.isNotEmpty && quantity > 0) {
          stockDeductions[itemDocId] = quantity;
        }
      }
      
      if (stockDeductions.isNotEmpty) {
        await _deductMultipleProductStocks(stockDeductions);
      }
      
    } catch (e) {
      print("Error deducting stock: $e");
    }
  }

  Future<void> _deductMultipleProductStocks(Map<String, int> productQuantities) async {
    try {
      for (final entry in productQuantities.entries) {
        await _productRepository.deductProductStock(entry.key, entry.value);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PartRequest>> searchPartRequests(String query) async {
    try {
      QuerySnapshot snapshot = await _firestoreService
          .getCollection(partRequestCol);

      List<PartRequest> allRequests = snapshot.docs
          .map((doc) => PartRequest.fromFirestore(doc))
          .toList();

      List<PartRequest> filtered = allRequests.where((request) =>
          request.requestId.toLowerCase().contains(query.toLowerCase()) ||
          request.remark.toLowerCase().contains(query.toLowerCase())
      ).toList();

      filtered.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      return filtered;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getRequestDisplayData(PartRequest request) async {
    Workshop? workshop;
    try {
      workshop = await getWorkshopById(request.workshopId);
      workshop ??= await getWorkshopByShopId(request.workshopId);
    } catch (e) {
      workshop = null;
    }

    List<Map<String, dynamic>> itemsWithDetails = [];
    double calculatedTotal = 0.0;

    for (ItemRequest itemRequest in request.itemList) {
      try {
        ItemDetail? itemDetail = await getItemDetail(itemRequest.itemDocId);
        if (itemDetail != null) {
          double subtotal = itemDetail.unitPrice * itemRequest.quantity;
          calculatedTotal += subtotal;

          bool hasEnoughStock = itemDetail.stockQuantity >= itemRequest.quantity;
          String? stockWarning;
          if (!hasEnoughStock) {
            stockWarning = "Insufficient stock! Available: ${itemDetail.stockQuantity}, Requested: ${itemRequest.quantity}";
          }

          itemsWithDetails.add({
            'detail': itemDetail,
            'quantity': itemRequest.quantity,
            'subtotal': subtotal,
            'hasEnoughStock': hasEnoughStock,
            'stockWarning': stockWarning,
          });
        } else {
          itemsWithDetails.add({
            'detail': null,
            'quantity': itemRequest.quantity,
            'subtotal': 0.0,
            'hasEnoughStock': false,
            'stockWarning': "Item not found in inventory",
          });
        }
      } catch (e) {
        print("Error fetching item ${itemRequest.itemDocId}: $e");
      }
    }

    bool allItemsHaveStock = itemsWithDetails.every((item) => item['hasEnoughStock'] == true);
    List<String> stockIssues = itemsWithDetails
        .where((item) => item['stockWarning'] != null)
        .map((item) => item['stockWarning'] as String)
        .toList();

    return {
      'request': PartRequest(
        id: request.id,
        requestId: request.requestId,
        status: request.status,
        statusColor: request.statusColor,
        requestType: request.requestType,
        totalPrice: calculatedTotal,
        orderDate: request.orderDate,
        remark: request.remark,
        workshopId: request.workshopId,
        itemList: request.itemList,
        createdAt: request.createdAt,
        updatedAt: request.updatedAt,
      ),
      'workshop': workshop,
      'itemsWithDetails': itemsWithDetails,
      'allItemsHaveStock': allItemsHaveStock,
      'stockIssues': stockIssues,
      'customerInfo': {
        'name': workshop?.personInChargeName ?? 'Unknown',
        'phone': workshop?.phoneNumber ?? 'Unknown',
      },
      'shippingAddress': {
        'workshopName': workshop?.shopName ?? 'Unknown Workshop',
        'address': workshop?.shopAddress ?? 'Unknown Address',
      },
    };
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA500';
      case 'approved':
        return '#4CAF50';
      case 'on hold':
        return '#2196F3';
      default:
        return '#9E9E9E';
    }
  }
}