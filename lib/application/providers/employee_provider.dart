import 'package:flutter/foundation.dart';
import 'package:sparix/data/models/employee.dart';
import 'package:sparix/data/repositories/employee_repository.dart';

class EmployeeProvider extends ChangeNotifier {
  final EmployeeRepository _employeeRepository = EmployeeRepository();

  Employee? _currentEmployee;
  List<Employee> _employees = [];
  bool _isLoading = false;
  String? _error;
  String _profileImageUrl = '';
  String get profileImageUrl => _profileImageUrl;

  // Getters
  Employee? get currentEmployee => _currentEmployee;
  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get employee by ID
  Future<void> getEmployeeById(String employeeId) async {
    _setLoading(true);
    _setError(null);

    try {
      final employee = await _employeeRepository.getEmployeeById(employeeId);
      _currentEmployee = employee;
      notifyListeners();
    } catch (e) {
      _setError('Failed to get employee: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Get employee by email
  Future<void> getEmployeeByEmail(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      final employee = await _employeeRepository.getEmployeeByEmail(email);
      _currentEmployee = employee;
      notifyListeners();
    } catch (e) {
      _setError('Failed to get employee: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Get all employees
  Future<void> getAllEmployees() async {
    _setLoading(true);
    _setError(null);

    try {
      final employeeList = await _employeeRepository.getAllEmployees();
      _employees = employeeList;
      notifyListeners();
    } catch (e) {
      _setError('Failed to get employees: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update employee
  Future<void> updateEmployee(Employee employee) async {
    _setLoading(true);
    _setError(null);

    try {
      await _employeeRepository.updateEmployee(employee);

      // Update current employee if it's the same one
      if (_currentEmployee?.employeeId == employee.employeeId) {
        _currentEmployee = employee;
      }

      // Update in employees list
      final index = _employees.indexWhere((e) => e.employeeId == employee.employeeId);
      if (index != -1) {
        _employees[index] = employee;
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to update employee: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Stream employee by ID (real-time updates)
  void streamEmployeeById(String employeeId) {
    _employeeRepository.streamEmployeeById(employeeId).listen(
          (employee) {
        _currentEmployee = employee;
        notifyListeners();
      },
      onError: (error) {
        _setError('Stream error: ${error.toString()}');
      },
    );
  }

  // Stream employee by email (real-time updates)
  void streamEmployeeByEmail(String email) {
    _employeeRepository.streamEmployeeByEmail(email).listen(
          (employee) {
        _currentEmployee = employee;
        notifyListeners();
      },
      onError: (error) {
        _setError('Stream error: ${error.toString()}');
      },
    );
  }

  // Check if employee exists
  Future<bool> employeeExists(String employeeId) async {
    try {
      return await _employeeRepository.employeeExists(employeeId);
    } catch (e) {
      _setError('Failed to check employee existence: ${e.toString()}');
      return false;
    }
  }

  // Get employee image
  Future<void> getEmployeeProfileImage(String employeeId) async {
    try {
      if (kDebugMode) {
        print('Attempting to fetch profile image for employeeId: $employeeId');
      }
      final url = await _employeeRepository.getEmployeeProfileImage(employeeId);
      if (url != null) {
        _profileImageUrl = url;
        if (kDebugMode) {
          print('Successfully fetched profile image URL: $url');
        }
        notifyListeners();
      } else {
        if (kDebugMode) {
          print('No profile image found for employeeId: $employeeId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching employee profile image for $employeeId: $e');
      }
      // Reset profile image URL on error
      _profileImageUrl = '';
      notifyListeners();
    }
  }

  // Generate new employee ID
  String generateEmployeeId() {
    return _employeeRepository.generateEmployeeId();
  }

  // Clear current employee
  void clearCurrentEmployee() {
    _currentEmployee = null;
    notifyListeners();
  }

  // Clear all data
  void clearAll() {
    _currentEmployee = null;
    _employees = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}