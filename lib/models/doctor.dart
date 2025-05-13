class Doctor {
  int? id;
  String name;
  String specialty;
  String clinic;

  Doctor({
    this.id,
    required this.name,
    required this.specialty,
    required this.clinic,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'clinic': clinic,
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'],
      name: map['name'],
      specialty: map['specialty'],
      clinic: map['clinic'],
    );
  }
}
