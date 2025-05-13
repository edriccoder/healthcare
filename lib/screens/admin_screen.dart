import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/doctor.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  List<Doctor> _doctors = [];
  List<Appointment> _appointments = [];
  List<User> _users = [];
  bool _isLoading = true;

  // List of appointment types
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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _doctors = await DatabaseHelper().getAllDoctors();
      _appointments = await DatabaseHelper().getAllAppointments();
      _users = await DatabaseHelper().getAllUsers();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
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
        title: const Text('Admin Panel'),
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
            icon: Icon(Icons.medical_services),
            label: 'Doctors',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                _showAddDoctorDialog();
              },
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildAppointmentsTab();
      case 2:
        return _buildDoctorsTab();
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
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // First row of stat cards
          Row(
            children: [
              _buildStatCard(
                title: 'Total Users',
                value: _users.length.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Total Doctors',
                value: _doctors.length.toString(),
                icon: Icons.medical_services,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Modified layout for the second row to avoid overflow
          Row(
            children: [
              _buildStatCard(
                title: 'Appointments', // Shortened from "Total Appointments"
                value: _appointments.length.toString(),
                icon: Icons.calendar_today,
                color: Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Pending', // Shortened from "Pending Appointments"
                value: _appointments
                    .where((a) => a.status == 'pending')
                    .length
                    .toString(),
                icon: Icons.pending_actions,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Recent Appointments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: _appointments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No appointments found')),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        _appointments.length > 5 ? 5 : _appointments.length,
                    separatorBuilder: (context, index) => const Divider(),
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
                      final user = _users.firstWhere(
                        (u) => u.id == appointment.userId,
                        orElse: () => User(
                          name: 'Unknown',
                          email: 'unknown',
                          password: '',
                        ),
                      );

                      return ListTile(
                        title: Text('${user.name} - ${doctor.name}'),
                        subtitle:
                            Text('${appointment.date} at ${appointment.time}'),
                        trailing: _buildStatusChip(appointment.status),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateAppointmentDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create New Appointment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),
        Expanded(
          child: _appointments.isEmpty
              ? const Center(
                  child: Text('No appointments found'),
                )
              : ListView.builder(
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
                    final user = _users.firstWhere(
                      (u) => u.id == appointment.userId,
                      orElse: () => User(
                        name: 'Unknown',
                        email: 'unknown',
                        password: '',
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Appointment #${appointment.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                _buildStatusChip(appointment.status),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoRow('Patient', user.name),
                            _buildInfoRow('Email', user.email),
                            _buildInfoRow('Appointment Type',
                                appointment.appointmentType),
                            _buildInfoRow('Doctor', doctor.name),
                            _buildInfoRow('Specialty', doctor.specialty),
                            _buildInfoRow('Clinic', doctor.clinic),
                            _buildInfoRow('Date', appointment.date),
                            _buildInfoRow('Time', appointment.time),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _updateAppointmentStatus(
                                        appointment,
                                        'confirmed',
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green,
                                    ),
                                    child: const Text('Confirm'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _updateAppointmentStatus(
                                        appointment,
                                        'cancelled',
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDoctorsTab() {
    return _doctors.isEmpty
        ? const Center(
            child: Text('No doctors found'),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _doctors.length,
            itemBuilder: (context, index) {
              final doctor = _doctors[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
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
                            radius: 24,
                            child: Text(
                              doctor.name.substring(0, 1),
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  doctor.specialty,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showEditDoctorDialog(doctor);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteDoctorDialog(doctor);
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('Specialty', doctor.specialty),
                      _buildInfoRow('Clinic', doctor.clinic),
                    ],
                  ),
                ),
              );
            },
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
          padding: const EdgeInsets.all(12), // Reduced padding from 16 to 12
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    // Added Flexible to prevent text overflow
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Reduced font size
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
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
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

  Future<void> _updateAppointmentStatus(
    Appointment appointment,
    String status,
  ) async {
    try {
      await DatabaseHelper().updateAppointmentStatus(appointment.id!, status);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment status updated to $status'),
          ),
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

  Future<void> _showAddDoctorDialog() async {
    final nameController = TextEditingController();
    final specialtyController = TextEditingController();
    final clinicController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Doctor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Doctor Name'),
              ),
              TextField(
                controller: specialtyController,
                decoration: const InputDecoration(labelText: 'Specialty'),
              ),
              TextField(
                controller: clinicController,
                decoration: const InputDecoration(labelText: 'Clinic'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  specialtyController.text.isEmpty ||
                  clinicController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      final doctor = Doctor(
        name: nameController.text,
        specialty: specialtyController.text,
        clinic: clinicController.text,
      );

      try {
        await DatabaseHelper().insertDoctor(doctor);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doctor added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding doctor: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditDoctorDialog(Doctor doctor) async {
    final nameController = TextEditingController(text: doctor.name);
    final specialtyController = TextEditingController(text: doctor.specialty);
    final clinicController = TextEditingController(text: doctor.clinic);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Doctor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Doctor Name'),
              ),
              TextField(
                controller: specialtyController,
                decoration: const InputDecoration(labelText: 'Specialty'),
              ),
              TextField(
                controller: clinicController,
                decoration: const InputDecoration(labelText: 'Clinic'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  specialtyController.text.isEmpty ||
                  clinicController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      final updatedDoctor = Doctor(
        id: doctor.id,
        name: nameController.text,
        specialty: specialtyController.text,
        clinic: clinicController.text,
      );

      try {
        await DatabaseHelper().updateDoctor(updatedDoctor);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doctor updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating doctor: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteDoctorDialog(Doctor doctor) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: Text('Are you sure you want to delete ${doctor.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await DatabaseHelper().deleteDoctor(doctor.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doctor deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting doctor: $e')),
          );
        }
      }
    }
  }

  Future<void> _showCreateAppointmentDialog() async {
    int? selectedUserId;
    int? selectedDoctorId;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = '09:00 AM';
    String selectedAppointmentType = _appointmentTypes[0]; // Default type

    final List<String> timeSlots = [
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

    final patients = _users.where((user) => !user.isAdmin).toList();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Create Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Patient',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  hint: const Text('Select Patient'),
                  value: selectedUserId,
                  items: patients.map((user) {
                    return DropdownMenuItem<int>(
                      value: user.id,
                      child: Text(user.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedUserId = value;
                    });
                  },
                  isExpanded: true,
                ),
                const SizedBox(height: 16),
                const Text('Select Appointment Type',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    value: selectedAppointmentType,
                    items: _appointmentTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAppointmentType = value!;
                      });
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select Doctor',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  hint: const Text('Select Doctor'),
                  value: selectedDoctorId,
                  items: _doctors.map((doctor) {
                    return DropdownMenuItem<int>(
                      value: doctor.id,
                      child: Text('${doctor.name} (${doctor.specialty})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDoctorId = value;
                    });
                  },
                  isExpanded: true,
                ),
                const SizedBox(height: 16),
                const Text('Select Date',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select Time',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  value: selectedTime,
                  items: timeSlots.map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTime = value!;
                    });
                  },
                  isExpanded: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedUserId == null || selectedDoctorId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select patient and doctor')),
                  );
                  return;
                }
                Navigator.pop(context);
                _createAppointment(
                  selectedUserId!,
                  selectedDoctorId!,
                  selectedDate,
                  selectedTime,
                  selectedAppointmentType,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _createAppointment(int userId, int doctorId, DateTime date,
      String time, String appointmentType) async {
    try {
      final appointment = Appointment(
        userId: userId,
        doctorId: doctorId,
        date: DateFormat('yyyy-MM-dd').format(date),
        time: time,
        status: 'confirmed',
        amount: 500.0,
        appointmentType: appointmentType,
      );

      await DatabaseHelper().createAppointmentForUser(appointment);

      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating appointment: $e')),
      );
    }
  }
}
