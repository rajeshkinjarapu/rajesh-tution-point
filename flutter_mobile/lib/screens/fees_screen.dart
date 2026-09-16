import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _feeStatusList = [];
  List<dynamic> _paymentsList = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _totalDues = 0.0;
  double _totalPaid = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      String studentId = '';
      if (userStr != null) {
        final user = jsonDecode(userStr);
        studentId = user['student'] != null ? user['student']['id'] : user['id'];
      }
      
      if (studentId.isEmpty) {
        setState(() {
          _errorMessage = 'Student ID not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final res = await ApiService.getFeeStatus(studentId);
      final payRes = await ApiService.getStudentPayments();
      
      if (res['success']) {
        setState(() {
          _feeStatusList = res['data'] ?? [];
          if (payRes['success']) {
            _paymentsList = payRes['data'] ?? [];
          }
          _calculateTotals();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to load fee details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _calculateTotals() {
    _totalDues = 0.0;
    _totalPaid = 0.0;

    for (var item in _feeStatusList) {
      final amountDue = double.tryParse(item['amountDue']?.toString() ?? '0') ?? 0.0;
      final amountPaid = double.tryParse(item['amountPaid']?.toString() ?? '0') ?? 0.0;

      _totalDues += amountDue;
      _totalPaid += amountPaid;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return const Color(0xFF10B981); // Emerald
      case 'PARTIAL':
        return const Color(0xFFF59E0B); // Amber
      case 'OVERDUE':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slight gray background
      drawer: const AppDrawer(currentRoute: 'fees'),
      appBar: AppBar(
        title: Text('My Fees & Dues', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Dues & Pending'),
            Tab(text: 'Payment History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchFees,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDuesTab(),
                    _buildReceiptsTab(),
                  ],
                ),
      bottomNavigationBar: _isLoading || _totalDues <= 0
          ? null
          : SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
                child: ElevatedButton(
                  onPressed: () {
                    final dueFees = _feeStatusList.where((item) => (double.tryParse(item['amountDue']?.toString() ?? '0') ?? 0.0) > 0).toList();
                    Navigator.pushNamed(context, '/student/fees/pay', arguments: dueFees);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1), // Premium Indigo
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: Text(
                    'Pay Now',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
          ),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchFees,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDuesTab() {
    return RefreshIndicator(
      onRefresh: _fetchFees,
      color: const Color(0xFF6366F1),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Fee Breakdown',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_feeStatusList.isEmpty)
              _buildEmptyState('No fee records found.', Icons.task_alt_rounded)
            else
              ..._feeStatusList.map((item) {
                final structure = item['feeStructure'] ?? {};
                final name = structure['name'] ?? 'Fee';
                final term = structure['term'] ?? 'General';
                final dueDateStr = structure['dueDate']?.toString().split('T')[0] ?? 'N/A';

                final discount = double.tryParse(item['discountAmount']?.toString() ?? '0') ?? 0.0;
                final amountPaid = double.tryParse(item['amountPaid']?.toString() ?? '0') ?? 0.0;
                final amountDue = double.tryParse(item['amountDue']?.toString() ?? '0') ?? 0.0;
                final originalAmount = double.tryParse(item['originalAmount']?.toString() ?? '0') ?? 0.0;
                final status = item['status']?.toString() ?? 'UNPAID';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.05),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                          border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0).withOpacity(0.5))),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
                              child: Icon(Icons.receipt_rounded, color: _getStatusColor(status), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Body
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBreakdownCol('Original', originalAmount, const Color(0xFF475569)),
                            if (discount > 0)
                              _buildBreakdownCol('Discount', discount, const Color(0xFF10B981)),
                            _buildBreakdownCol('Paid', amountPaid, const Color(0xFF6366F1)),
                            _buildBreakdownCol('Balance', amountDue, amountDue > 0 ? const Color(0xFFEF4444) : const Color(0xFF1E293B), isBold: true),
                          ],
                        ),
                      ),
                      
                      // Action footer if pending
                      if (amountDue > 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment Pending', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600)),
                              Icon(Icons.warning_rounded, size: 16, color: const Color(0xFFEF4444).withOpacity(0.7)),
                            ],
                          ),
                        )
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCol(String label, double amount, Color valColor, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Icon(icon, size: 64, color: const Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 20),
          Text(msg, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    double total = _totalPaid + _totalDues;
    if (total == 0) total = 1;
    double progress = _totalPaid / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 15, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Paid', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('₹${_totalPaid.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('Pending Balance', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('₹${_totalDues.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsTab() {
    if (_paymentsList.isEmpty && !_isLoading) {
      return _buildEmptyState('No payment history found', Icons.history_rounded);
    }

    return RefreshIndicator(
      onRefresh: _fetchFees,
      color: const Color(0xFF6366F1),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _paymentsList.length,
        itemBuilder: (context, index) {
          final payment = _paymentsList[index];
          final structure = payment['feeStructure'] ?? {};
          final amountPaid = double.tryParse(payment['amountPaid']?.toString() ?? '0') ?? 0.0;
          
          String paymentDateStr = payment['paymentDate']?.toString().split('T')[0] ?? '';
          if (paymentDateStr.startsWith('1970') || paymentDateStr.isEmpty) {
            paymentDateStr = payment['createdAt']?.toString().split('T')[0] ?? '';
          }
          if (paymentDateStr.startsWith('1970') || paymentDateStr.isEmpty) {
            paymentDateStr = 'N/A';
          }

          final status = payment['status']?.toString().toUpperCase() ?? 'PENDING';

          Color statusColor;
          if (status == 'COMPLETED' || status == 'PAID' || status == 'SUCCESS') {
            statusColor = const Color(0xFF10B981);
          } else if (status == 'PENDING' || status == 'PROCESSING') {
            statusColor = const Color(0xFFF59E0B);
          } else {
            statusColor = const Color(0xFFEF4444); // REJECTED / FAILED
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded, color: statusColor, size: 24),
              ),
              title: Text(
                structure['name'] ?? 'Fee Payment',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Date: ${paymentDateStr.isNotEmpty ? paymentDateStr : "N/A"}',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+ ₹${amountPaid.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(status == 'PENDING' ? 'PROCESSING' : status, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                  )
                ],
              ),
              onTap: status == 'COMPLETED' || status == 'PAID' || status == 'SUCCESS' 
                  ? () {
                      // Optionally show receipt or share here
                  } 
                  : null,
            ),
          );
        },
      ),
    );
  }
}
