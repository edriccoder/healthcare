import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../utils/database_helper.dart';

class PaymentScreen extends StatefulWidget {
  final Appointment appointment;
  final Doctor doctor;

  const PaymentScreen({
    super.key,
    required this.appointment,
    required this.doctor,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'Cash';
  bool _isProcessing = false;
  final double _consultationFee = 500.0; // Default consultation fee

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Cash',
      'icon': Icons.money,
      'description': 'Pay cash at clinic',
    },
    {
      'name': 'GCash',
      'icon': Icons.account_balance_wallet,
      'description': 'Pay using GCash e-wallet',
    },
    {
      'name': 'Credit Card',
      'icon': Icons.credit_card,
      'description': 'Pay using credit/debit card',
    },
  ];

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Update appointment with payment details
      await DatabaseHelper().updateAppointmentPayment(
          widget.appointment.id!,
          _selectedPaymentMethod,
          true, // Mark as paid
          _consultationFee);

      if (!mounted) return;

      // Show success message and go back to appointments
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Payment successful! Appointment confirmed.')),
      );

      // Pop twice to go back to home screen
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Doctor', widget.doctor.name),
                    _buildInfoRow('Specialty', widget.doctor.specialty),
                    _buildInfoRow(
                        'Appointment', widget.appointment.appointmentType),
                    _buildInfoRow('Clinic', widget.doctor.clinic),
                    _buildInfoRow('Date', widget.appointment.date),
                    _buildInfoRow('Time', widget.appointment.time),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Consultation Fee',
                      '₱${_consultationFee.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Methods Section
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                final isSelected = method['name'] == _selectedPaymentMethod;

                return Card(
                  elevation: isSelected ? 4 : 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color:
                          isSelected ? Colors.deepPurple : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = method['name'];
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.deepPurple
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              method['icon'],
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  method['description'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.deepPurple,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // Payment Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Payment',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),

            if (_selectedPaymentMethod == 'GCash' ||
                _selectedPaymentMethod == 'Credit Card')
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'This is a demo app. No actual payment will be processed.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.deepPurple : null,
            ),
          ),
        ],
      ),
    );
  }
}
