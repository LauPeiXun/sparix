import 'package:sparix/core/services/firebase_firestore_service.dart';
import 'package:sparix/core/services/firebase_storage_service.dart';
import 'package:sparix/data/models/employee.dart';

class EmployeeRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  static const String collectionName = 'employee';

  // Get employee by ID
  Future<Employee?> getEmployeeById(String employeeId) async {
    try {
      return await _firestoreService.getModel<Employee>(
        collection: collectionName,
        docId: employeeId,
        fromMap: (map) {
          // Add employeeId to the map since it's not included in Firestore document data
          final enrichedMap = {
            'employeeId': employeeId,
            ...map,
          };
          return Employee.fromJson(enrichedMap);
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get employee by email
  Future<Employee?> getEmployeeByEmail(String email) async {
    try {
      final docs = await _firestoreService.getDocumentsWhereEqualTo(
        collectionPath: collectionName,
        fieldName: 'gmail',
        value: email,
      );

      if (docs.isNotEmpty) {
        final doc = docs.first;
        return Employee.fromJson({
          'employeeId': doc.id,
          ...doc.data(),
        });
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  //Get employee image
  Future<String?> getEmployeeProfileImage(String employeeId) async {
    // Try different common image file extensions
    final extensions = ['jpg', 'jpeg', 'png', 'webp'];
    
    for (String ext in extensions) {
      try {
        final filename = '$employeeId.$ext';
        final url = await _storageService.getImage('employee_image', filename);
        if (url != null) {
          return url;
        }
      } catch (e) {
        // Continue to next extension
        continue;
      }
    }
    
    // Also try without extension (original approach)
    return await _storageService.getImage('employee_image', employeeId);
  }

  // Get all employees
  Future<List<Employee>> getAllEmployees() async {
    try {
      final snapshot = await _firestoreService.getCollection(collectionName);
      return snapshot.docs.map((doc) {
        return Employee.fromJson({
          'employeeId': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Create employee
  Future<void> createEmployee(Employee employee) async {
    try {
      await _firestoreService.setModel<Employee>(
        collection: collectionName,
        docId: employee.employeeId,
        model: employee,
        toMap: (model) => model.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update employee
  Future<void> updateEmployee(Employee employee) async {
    try {
      await _firestoreService.updateDocument(
        collection: collectionName,
        docId: employee.employeeId,
        data: employee.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Delete employee
  Future<void> deleteEmployee(String employeeId) async {
    try {
      await _firestoreService.deleteDocument(
        collection: collectionName,
        docId: employeeId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Stream employee by ID (real-time updates)
  Stream<Employee?> streamEmployeeById(String employeeId) {
    try {
      return _firestoreService.streamModels<Employee>(
        collection: collectionName,
        fromMap: (map) => Employee.fromJson(map),
        queryBuilder: (query) => query.where('employeeID', isEqualTo: employeeId),
      ).map((employees) => employees.isNotEmpty ? employees.first : null);
    } catch (e) {
      rethrow;
    }
  }
  
  // Stream all employees
  Stream<List<Employee>> streamAllEmployees() {
    try {
      return _firestoreService.streamModels<Employee>(
        collection: collectionName,
        fromMap: (map) => Employee.fromJson(map),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Stream employee by email (real-time updates)
  Stream<Employee?> streamEmployeeByEmail(String email) {
    try {
      return _firestoreService.streamModels<Employee>(
        collection: collectionName,
        fromMap: (map) => Employee.fromJson(map),
        queryBuilder: (query) => query.where('gmail', isEqualTo: email),
      ).map((employees) => employees.isNotEmpty ? employees.first : null);
    } catch (e) {
      rethrow;
    }
  }

  // Check if employee exists
  Future<bool> employeeExists(String employeeId) async {
    try {
      final doc = await _firestoreService.getDocument(
        collection: collectionName,
        docId: employeeId,
      );
      return doc.exists;
    } catch (e) {
      rethrow;
    }
  }

  // Generate new employee ID
  String generateEmployeeId() {
    return _firestoreService.generateDocId(collectionName);
  }
}