class Doctor {
  int? id;
  String name;
  String specialty;
  String clinic;
  String email; // Added for login
  String password; // Added for login

  Doctor({
    this.id,
    required this.name,
    required this.specialty,
    required this.clinic,
    this.email = '', // Default empty string
    this.password = '', // Default empty string
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'clinic': clinic,
      'email': email,
      'password': password,
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'],
      name: map['name'],
      specialty: map['specialty'],
      clinic: map['clinic'],
      email: map['email'] ?? '',
      password: map['password'] ?? '',
    );
  }
}
