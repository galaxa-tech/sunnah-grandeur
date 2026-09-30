class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
    };
  }

  UserModel copyWith({
    String? email,
    String? name,
    String? phone,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }
}
