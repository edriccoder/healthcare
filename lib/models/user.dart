class User {
  int? id;
  String name;
  String email;
  String password;
  bool isAdmin;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'isAdmin': isAdmin ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      isAdmin: map['isAdmin'] == 1,
    );
  }
}
