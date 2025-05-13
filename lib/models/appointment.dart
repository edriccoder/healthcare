class Appointment {
  int? id;
  int userId;
  int doctorId;
  String date;
  String time;
  String status;
  String? paymentMethod;
  bool isPaid;
  double amount;
  String appointmentType; // Added field for appointment type

  Appointment({
    this.id,
    required this.userId,
    required this.doctorId,
    required this.date,
    required this.time,
    this.status = 'pending',
    this.paymentMethod,
    this.isPaid = false,
    this.amount = 0.0,
    this.appointmentType = 'Consultation', // Default type
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'doctorId': doctorId,
      'date': date,
      'time': time,
      'status': status,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid ? 1 : 0,
      'amount': amount,
      'appointmentType': appointmentType,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      userId: map['userId'],
      doctorId: map['doctorId'],
      date: map['date'],
      time: map['time'],
      status: map['status'],
      paymentMethod: map['paymentMethod'],
      isPaid: map['isPaid'] == 1,
      amount: map['amount'] ?? 0.0,
      appointmentType: map['appointmentType'] ?? 'Consultation',
    );
  }
}
