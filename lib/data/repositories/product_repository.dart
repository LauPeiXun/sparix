import 'package:sparix/core/services/firebase_firestore_service.dart';
import 'package:sparix/core/services/firebase_storage_service.dart';
import 'package:sparix/data/models/spare_part.dart';
import 'dart:io';

class ProductRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  static const String collectionName = 'spare_part';

  /// Generate new product ID
  String generateProductId() {
    return _firestoreService.generateDocId(collectionName);
  }

  /// Add product to Firestore
  Future<void> addProduct(Product product) async {
    try {
      await _firestoreService.setModel<Product>(
        collection: collectionName,
        docId: product.productId,
        model: product,
        toMap: (model) => model.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Upload product image and get URL
  Future<String> uploadProductImage({
    required String productId,
    required File imageFile,
  }) async {
    try {
      // Upload image to Firebase Storage
      await _storageService.uploadImage(
        'product_images',
        '$productId.jpg',
        imageFile,
      );

      // Get download URL
      final imageUrl = await _storageService.getImage(
        'product_images',
        '$productId.jpg',
      );

      return imageUrl ?? '';
    } catch (e) {
      rethrow;
    }
  }

  /// Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      return await _firestoreService.getModel<Product>(
        collection: collectionName,
        docId: productId,
        fromMap: (map) {
          // Add productId to the map since it's not included in Firestore document data
          final enrichedMap = {
            'productId': productId,
            ...map,
          };
          return Product.fromJson(enrichedMap);
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _firestoreService.getCollection(collectionName);
      return snapshot.docs.map((doc) {
        return Product.fromJson({
          'productId': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Update product
  Future<void> updateProduct(Product product) async {
    try {
      await _firestoreService.updateDocument(
        collection: collectionName,
        docId: product.productId,
        data: product.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestoreService.deleteDocument(
        collection: collectionName,
        docId: productId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Check if product exists
  Future<bool> productExists(String productId) async {
    try {
      final doc = await _firestoreService.getDocument(
        collection: collectionName,
        docId: productId,
      );
      return doc.exists;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all products as a stream for real-time updates
  Stream<List<Product>> getAllProductsStream() {
    return _firestoreService.streamCollection(collection: collectionName)
        .map((snapshot) => snapshot.docs.map((doc) {
          return Product.fromJson({
            'productId': doc.id,
            ...doc.data(),
          });
        }).toList());
  }

  /// Get product by ID as a stream for real-time updates
  Stream<Product?> getProductByIdStream(String productId) {
    return _firestoreService.streamCollection(
      collection: collectionName,
      queryBuilder: (query) => query.where('productId', isEqualTo: productId).limit(1),
    ).map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Product.fromJson({
          'productId': doc.id,
          ...doc.data(),
        });
      }
      return null;
    });
  }

  /// Search products by name
  Future<List<Product>> searchProductsByName(String searchQuery) async {
    try {
      final snapshot = await _firestoreService.getCollection(collectionName);
      final allProducts = snapshot.docs.map((doc) {
        return Product.fromJson({
          'productId': doc.id,
          ...doc.data(),
        });
      }).toList();

      // Filter products by name
      final searchLower = searchQuery.toLowerCase();
      final filteredProducts = allProducts.where((product) {
        return product.name.toLowerCase().contains(searchLower);
      }).toList();

      // Sort by relevance (exact matches first, then contains)
      filteredProducts.sort((a, b) {
        final aName = a.name.toLowerCase();
        final bName = b.name.toLowerCase();
        
        final aStartsWith = aName.startsWith(searchLower);
        final bStartsWith = bName.startsWith(searchLower);
        
        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;
        
        return aName.compareTo(bName);
      });

      return filteredProducts;
    } catch (e) {
      rethrow;
    }
  }

  /// Deduct quantity
  Future<void> deductProductStock(String productId, int quantity) async {
    try {
      // Get the current product data
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Product not found: $productId');
      }

      // Calculate new stock (ensure it doesn't go negative)
      final newStock = (product.stock - quantity).clamp(0, product.stock);
      
      // Update the product with new stock
      final updatedProduct = product.copyWith(stock: newStock);
      await updateProduct(updatedProduct);
      
    } catch (e) {
      rethrow;
    }
  }

  /// Add quantity to product stock (for supplier orders)
  Future<void> addProductStock(String productId, int quantity) async {
    try {
      // Get the current product data
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Product not found: $productId');
      }

      // Calculate new stock by adding received quantity
      final newStock = product.stock + quantity;
      
      // Update the product with new stock
      final updatedProduct = product.copyWith(stock: newStock);
      await updateProduct(updatedProduct);
      
      print('Updated stock for product $productId: ${product.stock} + $quantity = $newStock');
      
    } catch (e) {
      print('Error updating stock for product $productId: $e');
      rethrow;
    }
  }

  /// Update stock for multiple products
  Future<void> updateMultipleProductStocks(Map<String, int> productQuantities) async {
    try {
      // Process each product stock update
      for (final entry in productQuantities.entries) {
        await addProductStock(entry.key, entry.value);
      }
      
      print('Updated stock for ${productQuantities.length} products');
      
    } catch (e) {
      print('Error updating multiple product stocks: $e');
      rethrow;
    }
  }
}