import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../models/user.dart';
import '../models/appointment.dart';
import '../utils/database_helper.dart';
import 'chat_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _selectedIndex = 0;
  late Doctor _currentDoctor;
  List<User> _patients = [];
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final doctor = ModalRoute.of(context)!.settings.arguments as Doctor;
    _currentDoctor = doctor;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _appointments =
          await DatabaseHelper().getDoctorAppointments(_currentDoctor.id!);
      _patients = await DatabaseHelper().getDoctorPatients(_currentDoctor.id!);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Portal'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Patients',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildAppointmentsTab();
      case 2:
        return _buildPatientsTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurple.shade300],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    _currentDoctor.name.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${_currentDoctor.name}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _currentDoctor.specialty,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _currentDoctor.clinic,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Statistics Cards
          Row(
            children: [
              _buildStatCard(
                title: 'Patients',
                value: _patients.length.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Appointments',
                value: _appointments.length.toString(),
                icon: Icons.calendar_today,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                title: 'Pending',
                value: _appointments
                    .where((a) => a.status == 'pending')
                    .length
                    .toString(),
                icon: Icons.pending_actions,
                color: Colors.amber,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Completed',
                value: _appointments
                    .where((a) => a.status == 'completed')
                    .length
                    .toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ],
          ),

          // Today's Appointments
          const SizedBox(height: 24),
          const Text(
            'Today\'s Appointments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTodayAppointments(),
        ],
      ),
    );
  }

  Widget _buildTodayAppointments() {
    final today = DateTime.now();
    final todayFormatted =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayAppointments =
        _appointments.where((a) => a.date == todayFormatted).toList();

    if (todayAppointments.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No appointments scheduled for today.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: todayAppointments.length,
      itemBuilder: (context, index) {
        final appointment = todayAppointments[index];
        final patient = _patients.firstWhere(
          (p) => p.id == appointment.userId,
          orElse: () => User(name: 'Unknown', email: 'unknown', password: ''),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                patient.name.substring(0, 1),
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(patient.name),
            subtitle:
                Text('${appointment.time} - ${appointment.appointmentType}'),
            trailing: _buildStatusChip(appointment.status),
            onTap: () {
              _showAppointmentDetailsDialog(context, appointment, patient);
            },
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsTab() {
    if (_appointments.isEmpty) {
      return const Center(child: Text('No appointments found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        final patient = _patients.firstWhere(
          (p) => p.id == appointment.userId,
          orElse: () => User(name: 'Unknown', email: 'unknown', password: ''),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        patient.name.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            patient.email,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(appointment.status),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: Text(
                    appointment.appointmentType,
                    style: TextStyle(
                      color: Colors.deepPurple.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoColumn(
                        Icons.calendar_today, 'Date', appointment.date),
                    _buildInfoColumn(
                        Icons.access_time, 'Time', appointment.time),
                    _buildInfoColumn(
                      Icons.payment,
                      'Paid',
                      appointment.isPaid ? 'Yes' : 'No',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                user: patient,
                                doctor: _currentDoctor,
                                isDoctor: true,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat with Patient'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _updateAppointmentStatus(appointment, 'completed');
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark as Completed'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
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

  Widget _buildPatientsTab() {
    if (_patients.isEmpty) {
      return const Center(child: Text('No patients found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final patient = _patients[index];
        final patientAppointments =
            _appointments.where((a) => a.userId == patient.id).toList();
        final latestAppointment = patientAppointments.isNotEmpty
            ? patientAppointments.reduce((a, b) =>
                DateTime.parse(a.date).isAfter(DateTime.parse(b.date)) ? a : b)
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                patient.name.substring(0, 1),
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(patient.name),
            subtitle: Text(latestAppointment != null
                ? 'Latest appointment: ${latestAppointment.date}'
                : 'No appointments'),
            trailing: IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      user: patient,
                      doctor: _currentDoctor,
                      isDoctor: true,
                    ),
                  ),
                );
              },
            ),
            onTap: () {
              _showPatientDetailsDialog(context, patient, patientAppointments);
            },
          ),
        );
      },
    );
  }

  Future<void> _updateAppointmentStatus(
      Appointment appointment, String status) async {
    try {
      await DatabaseHelper().updateAppointmentStatus(appointment.id!, status);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  void _showAppointmentDetailsDialog(
      BuildContext context, Appointment appointment, User patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointment with ${patient.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Date', appointment.date),
            _buildInfoRow('Time', appointment.time),
            _buildInfoRow('Type', appointment.appointmentType),
            _buildInfoRow('Status', appointment.status),
            _buildInfoRow('Payment', appointment.isPaid ? 'Paid' : 'Not paid'),
            if (appointment.paymentMethod != null &&
                appointment.paymentMethod!.isNotEmpty)
              _buildInfoRow('Method', appointment.paymentMethod!),
            if (appointment.amount > 0)
              _buildInfoRow(
                  'Amount', '₱${appointment.amount.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    user: patient,
                    doctor: _currentDoctor,
                    isDoctor: true,
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.deepPurple,
            ),
            child: const Text('Chat with Patient'),
          ),
        ],
      ),
    );
  }

  void _showPatientDetailsDialog(
      BuildContext context, User patient, List<Appointment> appointments) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(patient.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Email', patient.email),
            _buildInfoRow('Total Appointments', appointments.length.toString()),
            _buildInfoRow(
                'Pending',
                appointments
                    .where((a) => a.status == 'pending')
                    .length
                    .toString()),
            _buildInfoRow(
                'Completed',
                appointments
                    .where((a) => a.status == 'completed')
                    .length
                    .toString()),
            _buildInfoRow(
                'Cancelled',
                appointments
                    .where((a) => a.status == 'cancelled')
                    .length
                    .toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    user: patient,
                    doctor: _currentDoctor,
                    isDoctor: true,
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.deepPurple,
            ),
            child: const Text('Chat with Patient'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
