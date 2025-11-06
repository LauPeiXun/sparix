import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add data to a collection
  Future<void> addData({
    required String collection,
    required Map<String, dynamic> data,
    String? docId,
  }) async {
    try {
      if (docId != null) {
        await _firestore.collection(collection).doc(docId).set(data);
      } else {
        await _firestore.collection(collection).add(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Add data to a collection by path segments
  Future<void> addDataByPath({
    required List<String> pathSegments,
    required Map<String, dynamic> data,
    String? docId,
  }) async {
    try {
      if (pathSegments.length.isOdd && pathSegments.isNotEmpty) {
        CollectionReference collectionRef = _firestore.collection(
          pathSegments.join('/'),
        );
        await collectionRef.add(data);
      } else {
        throw ArgumentError(
          "Path must have an odd number of segments (ending with a collection).",
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Add or set a document from model
  Future<void> setModel<T>({
    required String collection,
    required String docId,
    required T model,
    required Map<String, dynamic> Function(T model) toMap,
  }) async {
    try {
      final data = toMap(model);
      await _firestore.collection(collection).doc(docId).set(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get model from document
  Future<T?> getModel<T>({
    required String collection,
    required String docId,
    required T Function(Map<String, dynamic> map) fromMap,
  }) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();

      if (doc.exists) {
        return fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Read a document
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      rethrow;
    }
  }

  // Get all data by collection
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(
      String collectionPath,
      ) async {
    return await FirebaseFirestore.instance.collection(collectionPath).get();
  }

  /// Read a document by path segments
  Stream<QuerySnapshot> getDataByPath({
    required List<String> pathSegments,
    String? orderByField,
    bool descending = false,
  }) {
    if (pathSegments.length.isOdd && pathSegments.isNotEmpty) {
      CollectionReference collectionRef = _firestore.collection(
        pathSegments.join('/'),
      );

      Query query = collectionRef;

      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      }

      return query.snapshots();
    } else {
      throw ArgumentError(
        "Path must have an odd number of segments (ending with a collection).",
      );
    }
  }

  /// Stream list of models from a collection
  Stream<List<T>> streamModels<T>({
    required String collection,
    required T Function(Map<String, dynamic> map) fromMap,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)?
    queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromMap(doc.data())).toList();
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String collection,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)?
    queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }

    // Add this to force server-side data (NO cache)
    return query.snapshots(includeMetadataChanges: true);
  }

  /// Update document
  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete document
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a document by path segments
  Future<void> deleteDataByPath({required List<String> pathSegments}) async {
    try {
      if (pathSegments.length.isEven && pathSegments.length >= 2) {
        DocumentReference docRef = _firestore.doc(pathSegments.join('/'));
        await docRef.delete();
      } else {
        throw ArgumentError(
          "Path must have an even number of segments (collection/doc pairs).",
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get Document by array constraint
  Future<List<QueryDocumentSnapshot>> getDocumentsWhereArrayContains({
    required String collectionPath,
    required String fieldName,
    required dynamic value,
  }) async {
    final querySnapshot =
    await _firestore
        .collection(collectionPath)
        .where(fieldName, arrayContains: value)
        .get();

    return querySnapshot.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getDocumentsWhereEqualTo({
    required String collectionPath,
    required String fieldName,
    required dynamic value,
  }) async {
    final querySnapshot =
    await _firestore
        .collection(collectionPath)
        .where(fieldName, isEqualTo: value)
        .get();

    return querySnapshot.docs;
  }

  /// Generate a new document ID (without writing any data)
  String generateDocId(String collection) {
    return _firestore.collection(collection).doc().id;
  }

  setDataByPath({
    required List<String> pathSegments,
    required Map<String, dynamic> data,
  }) {}

  streamDocument({required String collection, required String docId}) {}
}
