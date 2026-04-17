class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; 
  final String? pharmacyName;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.pharmacyName,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Patient',
      pharmacyName: data['pharmacyName'],
    );
  }
}