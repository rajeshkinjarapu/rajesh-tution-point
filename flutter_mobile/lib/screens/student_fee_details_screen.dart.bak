import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'record_fee_payment_screen.dart';
import 'package:intl/intl.dart';

class StudentFeeDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentFeeDetailsScreen({super.key, required this.student});

  @override
  State<StudentFeeDetailsScreen> createState() => _StudentFeeDetailsScreenState();
}

class _StudentFeeDetailsScreenState extends State<StudentFeeDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _structures = [];
  List<dynamic> _payments = [];
  List<dynamic> _discounts = [];

  double _totalAmount = 0.0;
  double _totalDiscount = 0.0;
  double _totalPaid = 0.0;
  double _totalPending = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFeeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFeeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getFeeStructures(),
      ]);

      final structuresRes = results[0];

      if (structuresRes['success']) {
        final allStructures = structuresRes['data'] ?? [];
        
        final studentId = widget.student['id'];
        final classId = widget.student['classId'];

        _structures = allStructures.where((s) => s['studentId'] == studentId || s['classId'] == classId).toList();
        
        final studentRes = await ApiService.getStudentById(studentId);
        if (studentRes['success'] && studentRes['data'] != null) {
          _payments = studentRes['data']['feePayments'] ?? [];
          _discounts = studentRes['data']['feeDiscounts'] ?? [];
        } else {
          _payments = widget.student['feePayments'] ?? [];
          _discounts = widget.student['feeDiscounts'] ?? [];
        }

        _calculateTotals();

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = structuresRes['message'] ?? 'Failed to load fee details';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _calculateTotals() {
    _totalAmount = 0.0;
    _totalDiscount = 0.0;
    _totalPaid = 0.0;
    
    for (var st in _structures) {
      _totalAmount += double.tryParse(st['amount']?.toString() ?? '0') ?? 0.0;
    }

    for (var d in _discounts) {
      _totalDiscount += double.tryParse(d['amount']?.toString() ?? '0') ?? 0.0;
    }

    for (var p in _payments) {
      _totalPaid += double.tryParse(p['amountPaid']?.toString() ?? '0') ?? 0.0;
    }

    _totalPending = _totalAmount - _totalDiscount - _totalPaid;
    if (_totalPending < 0) _totalPending = 0.0;
  }

  void _navigateToRecordPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordFeePaymentScreen(
          student: widget.student,
          feeStructures: _structures,
          payments: _payments,
          discounts: _discounts,
        ),
      ),
    ).then((_) => _fetchFeeData());
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.student['user'] ?? {};
    final name = user['name'] ?? 'Unknown';
    final admissionNo = widget.student['admissionNumber'] ?? 'N/A';
    final cls = widget.student['class'] != null ? '${widget.student['class']['name']} - ${widget.student['class']['section']}' : 'N/A';
    final photoUrl = user['photoUrl'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Student Fee Ledger',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchFeeData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    // Premium Gradient Header Area
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: photoUrl != null && photoUrl.toString().isNotEmpty
                                  ? Image.network(
                                      ApiService.getImageUrl(photoUrl.toString()),
                                      fit: BoxFit.cover,
                                      headers: const {'ngrok-skip-browser-warning': '69420'},
                                      errorBuilder: (context, error, stackTrace) => _buildInitials(name),
                                    )
                                  : _buildInitials(name),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Student Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Class: $cls',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Adm: $admissionNo',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Floating Summary Cards
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(child: _buildSummaryCard('Pending Due', _totalPending, const Color(0xFFEF4444), Colors.white, Icons.account_balance_wallet_rounded)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildSummaryCard('Total Paid', _totalPaid, const Color(0xFF10B981), Colors.white, Icons.check_circle_outline_rounded)),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF6366F1),
                      unselectedLabelColor: const Color(0xFF64748B),
                      indicatorColor: const Color(0xFF6366F1),
                      indicatorWeight: 4,
                      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                      unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Fee Ledger'),
                        Tab(text: 'Payment History'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLedgerTab(),
                          _buildTransactionsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToRecordPayment,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_card_rounded, color: Colors.white),
        label: Text(
          'Collect Fee',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, Color bgColor, IconData icon) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.withOpacity(0.8)),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: color.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(amount),
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTab() {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    
    if (_structures.isEmpty) {
      return Center(
        child: Text('No fee structures assigned.', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _structures.length,
      itemBuilder: (context, index) {
        final st = _structures[index];
        final id = st['id'];
        final amount = double.tryParse(st['amount']?.toString() ?? '0') ?? 0.0;
        final headName = st['head'] != null ? st['head']['name'] : 'Fee';
        
        // Calculate paid and discount for this specific structure
        double paid = 0;
        for (var p in _payments) {
          if (p['feeStructureId'] == id) {
            paid += double.tryParse(p['amountPaid']?.toString() ?? '0') ?? 0.0;
          }
        }
        
        double disc = 0;
        for (var d in _discounts) {
          if (d['feeStructureId'] == id) {
            disc += double.tryParse(d['amount']?.toString() ?? '0') ?? 0.0;
          }
        }
        
        final pending = amount - paid - disc;
        final isCleared = pending <= 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCleared ? const Color(0xFF10B981).withOpacity(0.05) : const Color(0xFFEF4444).withOpacity(0.05),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0).withOpacity(0.5))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      headName,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1E293B),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCleared ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCleared ? 'CLEARED' : 'PENDING',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLedgerItem('Total', currencyFormat.format(amount), const Color(0xFF64748B)),
                    _buildLedgerItem('Discount', currencyFormat.format(disc), const Color(0xFF10B981)),
                    _buildLedgerItem('Paid', currencyFormat.format(paid), const Color(0xFF6366F1)),
                    _buildLedgerItem('Due', currencyFormat.format(pending > 0 ? pending : 0), const Color(0xFFEF4444), isBold: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLedgerItem(String label, String value, Color color, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
              child: const Icon(Icons.history_rounded, size: 64, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 20),
            Text('No transactions found', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        final amount = double.tryParse(payment['amountPaid']?.toString() ?? '0') ?? 0.0;
        final method = payment['paymentMethod'] ?? 'CASH';
        final status = payment['status'] ?? 'PAID';
        final date = payment['paymentDate'] != null ? DateTime.tryParse(payment['paymentDate']) : null;
        
        final headName = payment['feeStructure'] != null && payment['feeStructure']['head'] != null 
            ? payment['feeStructure']['head']['name'] 
            : 'Fee Payment';

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
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 24),
            ),
            title: Text(
              headName,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Text(
                    date != null ? DateFormat('MMM dd, yyyy').format(date) : 'N/A',
                    style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      method,
                      style: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+ ${currencyFormat.format(amount)}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF10B981),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: status == 'PAID' ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      color: status == 'PAID' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.outfit(
          color: const Color(0xFF6366F1),
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
