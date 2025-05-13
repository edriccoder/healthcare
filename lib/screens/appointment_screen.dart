import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/doctor.dart';
import '../models/appointment.dart';
import '../utils/database_helper.dart';
import '../screens/payment_screen.dart';

class AppointmentScreen extends StatefulWidget {
  final User user;
  final List<Doctor> doctors;
  final int? initialDoctorIndex;

  const AppointmentScreen({
    super.key,
    required this.user,
    required this.doctors,
    this.initialDoctorIndex,
  });

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  late int _selectedDoctorIndex;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '09:00 AM';
  String _selectedAppointmentType = 'General Consultation';
  bool _isLoading = false;
  final List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
  ];
  final List<String> _appointmentTypes = [
    'General Consultation',
    'Blood Test',
    'X-Ray Scan',
    'Lung Cancer Screening',
    'Bone Density Scan',
    'MRI Scan',
    'CT Scan',
    'Ultrasound',
    'Physical Therapy',
    'Dental Checkup'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDoctorIndex = widget.initialDoctorIndex ?? 0;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    setState(() => _isLoading = true);

    try {
      final doctor = widget.doctors[_selectedDoctorIndex];
      final appointment = Appointment(
        userId: widget.user.id!,
        doctorId: doctor.id!,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        time: _selectedTime,
        amount: 500.0, // Default consultation fee
        appointmentType: _selectedAppointmentType,
      );

      final appointmentId =
          await DatabaseHelper().insertAppointment(appointment);

      // Get the appointment with ID
      appointment.id = appointmentId;

      if (!mounted) return;

      // Navigate to payment screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            appointment: appointment,
            doctor: doctor,
          ),
        ),
      );

      // If payment successful or we're back from payment, return to previous screen
      if (result == true || result == null) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking appointment: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Selection
            const Text(
              'Select Doctor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Doctor',
                  border: InputBorder.none,
                ),
                value: _selectedDoctorIndex,
                items: List.generate(
                  widget.doctors.length,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(
                      '${widget.doctors[index].name} (${widget.doctors[index].specialty})',
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedDoctorIndex = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Date Selection
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.deepPurple),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time Selection
            const Text(
              'Select Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((time) {
                  final isSelected = time == _selectedTime;

                  return ChoiceChip(
                    label: Text(time),
                    selected: isSelected,
                    selectedColor: Colors.deepPurple,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Appointment Type Selection
            const Text(
              'Select Appointment Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Appointment Type',
                  border: InputBorder.none,
                ),
                value: _selectedAppointmentType,
                items: _appointmentTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAppointmentType = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Clinic information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clinic Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.doctors[_selectedDoctorIndex].clinic,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Book button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Book Appointment',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
