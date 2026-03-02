class User {
  final int? id;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? governorate;
  final String? role;

  User({
    this.id,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.governorate,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phoneNumber: json['phone_number'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      governorate: json['governorate'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'governorate': governorate,
      'role': role,
    };
  }
}
