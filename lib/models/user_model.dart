class UserModel {
  String? uid, name, email, role, phone;
  UserModel({this.uid, this.name, this.email, this.role, this.phone});

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'],
    name: map['name'],
    email: map['email'],
    role: map['role'],
    phone: map['phone'],
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
  };
}
