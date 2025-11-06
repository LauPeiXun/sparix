class Employee {
  final String employeeId;
  final String gmail;
  final String name;
  final String profilePictureUrl;

  Employee({
    required this.employeeId,
    required this.gmail,
    required this.name,
    this.profilePictureUrl = '',
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeId: json['employeeId'] ?? json['employeeId'] ?? '',
      gmail: json['gmail'] ?? '',
      name: json['name'] ?? '',
      profilePictureUrl: json['profilePictureUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'gmail': gmail,
      'name': name,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  Employee copyWith({
    String? employeeId,
    String? gmail,
    String? name,
    String? profilePictureUrl,
  }) {
    return Employee(
      employeeId: employeeId ?? this.employeeId,
      gmail: gmail ?? this.gmail,
      name: name ?? this.name,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee &&
        other.employeeId == employeeId &&
        other.gmail == gmail &&
        other.name == name;
  }

  @override
  int get hashCode => employeeId.hashCode ^ gmail.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'Employee(employeeId: $employeeId, gmail: $gmail, name: $name)';
  }
}