import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';
import 'package:intl/intl.dart';

class CompletedAppointmentsScreen extends StatefulWidget {
  final User user;

  const CompletedAppointmentsScreen({
    super.key,
    required this.user,
  });

  @override
  State<CompletedAppointmentsScreen> createState() =>
      _CompletedAppointmentsScreenState();
}

class _CompletedAppointmentsScreenState
    extends State<CompletedAppointmentsScreen> {
  List<Appointment> _appointments = [];
  List<Doctor> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedAppointments();
  }

  Future<void> _loadCompletedAppointments() async {
    setState(() => _isLoading = true);

    try {
      _appointments =
          await DatabaseHelper().getCompletedAppointments(widget.user.id!);
      _doctors = await DatabaseHelper().getAllDoctors();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointments: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Appointments'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? _buildEmptyState()
              : _buildAppointmentsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No completed appointments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your completed appointments will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        final doctor = _doctors.firstWhere(
          (d) => d.id == appointment.doctorId,
          orElse: () => Doctor(
            name: 'Unknown',
            specialty: 'Unknown',
            clinic: 'Unknown',
          ),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.check, color: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            doctor.specialty,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Text(
                        'COMPLETED',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoColumn(
                      Icons.calendar_today,
                      'Date',
                      DateFormat('MMM dd, yyyy').format(
                          DateFormat('yyyy-MM-dd').parse(appointment.date)),
                    ),
                    _buildInfoColumn(
                      Icons.access_time,
                      'Time',
                      appointment.time,
                    ),
                    _buildInfoColumn(
                      Icons.location_on,
                      'Clinic',
                      doctor.clinic,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Type: ${appointment.appointmentType}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      appointment.paymentMethod ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Amount Paid',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '₱${appointment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(IconData icon, String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
