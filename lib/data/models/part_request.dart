import 'package:cloud_firestore/cloud_firestore.dart';

class ItemRequest {
  final String itemDocId;
  final int quantity;

  ItemRequest({
    required this.itemDocId,
    required this.quantity,
  });

  factory ItemRequest.fromMap(Map<String, dynamic> map) {
    return ItemRequest(
      itemDocId: map['itemDocId'] ?? '',
      quantity: map['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemDocId': itemDocId,
      'quantity': quantity,
    };
  }
}

class Workshop {
  final String? id;
  final String personInChargeId;
  final String personInChargeName;
  final String phoneNumber;
  final String shopAddress;
  final String shopId;
  final String shopName;

  Workshop({
    this.id,
    required this.personInChargeId,
    required this.personInChargeName,
    required this.phoneNumber,
    required this.shopAddress,
    required this.shopId,
    required this.shopName,
  });

  factory Workshop.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Workshop document data is null');
    }
    return Workshop(
      id: doc.id,
      personInChargeId: data['personInChargeId'] ?? '',
      personInChargeName: data['personInChargeName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      shopAddress: data['shopAddress'] ?? '',
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
    );
  }
}

class ItemDetail {
  final String id;
  final String title;
  final String productCode;
  final String description;
  final String imagePath;
  final double unitPrice;
  final String category;
  final bool inStock;
  final int stockQuantity;

  ItemDetail({
    required this.id,
    required this.title,
    required this.productCode,
    required this.description,
    required this.imagePath,
    required this.unitPrice,
    required this.category,
    required this.inStock,
    required this.stockQuantity,
  });

  factory ItemDetail.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('ItemDetail document data is null');
    }

    String description = '';
    if (data['description'] is List) {
      description = (data['description'] as List).join(' ');
    } else if (data['description'] is String) {
      description = data['description'];
    }
    
    return ItemDetail(
      id: doc.id,
      title: data['name'] ?? data['title'] ?? '',
      productCode: data['productId'] ?? data['productCode'] ?? data['code'] ?? '',
      description: description,
      imagePath: data['imageUrl'] ?? data['imagePath'] ?? '',
      unitPrice: _parsePrice(data['salesAmount'] ?? data['price'] ?? data['unitPrice']),
      category: data['category'] ?? '',
      inStock: data['status'] == 'Available',
      stockQuantity: data['stock'] ?? data['stockQuantity'] ?? 0,
    );
  }

  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    }
    return 0.0;
  }
}

class PartRequest {
  final String? id;
  final String requestId;
  final String status;
  final String statusColor;
  final String requestType;
  final double totalPrice;
  final DateTime orderDate;
  final String remark;
  final String workshopId;
  final List<ItemRequest> itemList;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PartRequest({
    this.id,
    required this.requestId,
    required this.status,
    required this.statusColor,
    required this.requestType,
    required this.totalPrice,
    required this.orderDate,
    required this.remark,
    required this.workshopId,
    required this.itemList,
    this.createdAt,
    this.updatedAt,
  });

  factory PartRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('PartRequest document data is null');
    }

    data.forEach((key, value) {
      print('  $key: $value (type: ${value.runtimeType})');
    });

    List<ItemRequest> itemList = [];
    if (data['itemLIst'] != null) {

      if (data['itemLIst'] is List) {
        List<dynamic> rawList = data['itemLIst'] as List;
        for (int i = 0; i < rawList.length; i++) {
          print('Item $i: ${rawList[i]} (type: ${rawList[i].runtimeType})');
        }

        itemList = rawList
            .map((item) => ItemRequest.fromMap(item as Map<String, dynamic>))
            .toList();

      } else if (data['itemLIst'] is Map) {
        itemList = [ItemRequest.fromMap(data['itemLIst'] as Map<String, dynamic>)];
      }
    } else {
      print('No itemLIst found in Firebase data');
    }

    return PartRequest(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      status: data['status'] ?? 'pending',
      statusColor: data['statusColor'] ?? '#FFA500',
      requestType: data['requestType'] ?? 'Work Order',
      totalPrice: 0.0,
      orderDate: PartRequest._parseTimestamp(data['orderDate']),
      remark: data['remark'] ?? '',
      workshopId: data['workshopId'] ?? '',
      itemList: itemList,
      createdAt: data['createdAt'] != null ? PartRequest._parseTimestamp(data['createdAt']) : null,
      updatedAt: data['updatedAt'] != null ? PartRequest._parseTimestamp(data['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'status': status,
      'statusColor': statusColor,
      'requestType': requestType,
      'orderDate': Timestamp.fromDate(orderDate),
      'remark': remark,
      'workshopId': workshopId,
      'itemLIst': itemList.map((item) => item.toMap()).toList(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is Map<String, dynamic> && timestamp.containsKey('__time__')) {
      return DateTime.parse(timestamp['__time__']);
    }

    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }

    return DateTime.now();
  }
}