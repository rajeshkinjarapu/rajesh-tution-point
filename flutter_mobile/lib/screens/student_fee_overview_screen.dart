import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dart:convert';

class StudentFeeOverviewScreen extends StatefulWidget {
  const StudentFeeOverviewScreen({super.key});

  @override
  State<StudentFeeOverviewScreen> createState() => _StudentFeeOverviewScreenState();
}

class _StudentFeeOverviewScreenState extends State<StudentFeeOverviewScreen> {
  bool _isLoading = true;
  double _totalFee = 0;
  double _totalPaid = 0;
  double _totalDue = 0;
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetchFeeStatus();
  }

  Future<void> _fetchFeeStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      if (userStr != null) {
        final user = jsonDecode(userStr);
        final studentId = user['id'];

        final response = await ApiService.getFeeStatus(studentId);
        if (response['success']) {
          final data = response['data'];
          setState(() {
            _totalFee = (data['totalFee'] ?? 0).toDouble();
            _totalPaid = (data['totalPaid'] ?? 0).toDouble();
            _totalDue = (data['totalDue'] ?? 0).toDouble();
            _payments = data['payments'] ?? [];
            _isLoading = false;
          });
        } else {
          _showError(response['message'] ?? 'Failed to load fee status');
        }
      }
    } catch (e) {
      _showError('Error connecting to server: $e');
    }
  }

  void _showError(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Fees Overview', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF4B497B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildRecentHistory(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _isLoading || _totalDue <= 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/student/fees/pay', arguments: _totalDue);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: Text(
                    'Pay Now (₹${_totalDue.toStringAsFixed(0)})',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    double progress = _totalFee > 0 ? _totalPaid / _totalFee : 0;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Text('Academic Year 2024-25', style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_totalDue > 0 ? Colors.orange : Colors.green),
                ),
              ),
              Column(
                children: [
                  Text('Paid', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14)),
                  Text('${(progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountItem('Total Fee', _totalFee, Colors.blue),
              _buildAmountItem('Paid', _totalPaid, Colors.green),
              _buildAmountItem('Due', _totalDue, Colors.orange),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAmountItem(String label, double amount, MaterialColor color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('₹${amount.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color[700])),
      ],
    );
  }

  Widget _buildRecentHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/student/fees/history', arguments: _payments);
                },
                child: Text('View All', style: GoogleFonts.poppins(color: const Color(0xFF4B497B), fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 8),
          if (_payments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('No payments found', style: GoogleFonts.poppins(color: Colors.grey)),
              ),
            )
          else
            ..._payments.take(3).map((payment) => _buildPaymentCard(payment)),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    String status = payment['status'] ?? 'PENDING';
    Color statusColor = status == 'APPROVED' ? Colors.green : (status == 'REJECTED' ? Colors.red : Colors.orange);
    IconData statusIcon = status == 'APPROVED' ? Icons.check_circle : (status == 'REJECTED' ? Icons.cancel : Icons.pending);
    
    // Format date
    String dateStr = 'Unknown Date';
    if (payment['paymentDate'] != null) {
      try {
        final d = DateTime.parse(payment['paymentDate']);
        dateStr = '${d.day}/${d.month}/${d.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹${(payment['amount'] ?? 0).toString()}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(dateStr, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
            ),
          )
        ],
      ),
    );
  }
}
