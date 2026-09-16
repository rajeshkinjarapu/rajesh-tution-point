import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'student_fee_search_screen.dart';
import 'fee_structure_management_screen.dart';
import 'fee_settings_screen.dart';
import 'fee_installment_report_screen.dart';
import 'fee_receipts_screen.dart';
import 'add_student_fee_screen.dart';
import 'transactions_screen.dart';
import 'student_fee_details_screen.dart';
import 'admin_pending_fees_screen.dart';
import 'admin_payment_settings_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _payments = [];
  List<dynamic> _structures = [];

  double _totalCollected = 0.0;
  double _todayCollected = 0.0;
  double _pendingDues = 0.0;
  double _totalExpected = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getFeePayments(),
        ApiService.getFeeStructures(),
        ApiService.getAdminDashboardStats(), // Try fetching admin stats as fallback for real total revenue
      ]);

      final paymentsRes = results[0];
      final structuresRes = results[1];
      final adminStatsRes = results[2];

      if (paymentsRes['success'] && structuresRes['success']) {
        setState(() {
          _payments = paymentsRes['data'] ?? [];
          _structures = structuresRes['data'] ?? [];
          
          _calculateKPIs(adminStatsRes['success'] ? adminStatsRes['data'] : null);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = paymentsRes['message'] ?? structuresRes['message'] ?? 'Failed to load finance data';
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

  void _calculateKPIs(Map<String, dynamic>? adminStats) {
    _totalCollected = 0.0;
    _todayCollected = 0.0;
    _pendingDues = 0.0;
    _totalExpected = 0.0;

    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    for (var payment in _payments) {
      final amount = double.tryParse(payment['amountPaid']?.toString() ?? '0.0') ?? 0.0;
      
      _totalCollected += amount;

      final payDate = payment['paymentDate']?.toString() ?? payment['createdAt']?.toString() ?? '';
      
      if (payDate.startsWith(todayStr)) {
        _todayCollected += amount;
      }
    }

    // Attempt to calculate real expected (multiplying by students if class data was available, but we sum for now)
    for (var struct in _structures) {
      _totalExpected += double.tryParse(struct['amount']?.toString() ?? '0.0') ?? 0.0;
    }

    // If admin stats provided a totalRevenue, we can use it, but local sum should match if we fetched all payments
    if (adminStats != null && adminStats['totalRevenue'] != null) {
      _totalCollected = (adminStats['totalRevenue'] ?? 0).toDouble();
    }

    _pendingDues = _totalExpected - _totalCollected;
    if (_pendingDues < 0) _pendingDues = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: const AppDrawer(currentRoute: 'fees'),
      appBar: AppBar(
        title: Text('Finance & Fees', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _errorMessage != null
              ? _buildErrorView()
              : SingleChildScrollView(
                  child: _buildDashboardContent(),
                ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKPIGrid(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Finance Services', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              const SizedBox(height: 10),
              _buildModulesGrid(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKPIGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Collected',
                  value: NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(_totalCollected),
                  icon: Icons.account_balance_wallet_rounded,
                  colors: [const Color(0xFF10B981), const Color(0xFF34D399)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Pending Dues',
                  value: NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(_pendingDues),
                  icon: Icons.warning_amber_rounded,
                  colors: [const Color(0xFFF43F5E), const Color(0xFFFB7185)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Today Collection',
                  value: NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(_todayCollected),
                  icon: Icons.today_rounded,
                  colors: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Expected',
                  value: NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(_totalExpected),
                  icon: Icons.account_balance,
                  colors: [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required List<Color> colors}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(height: 6),
          Text(title, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 0),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.blueGrey, fontSize: 15)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesGrid() {
    final modules = [
      {'title': 'Pending', 'desc': 'Approvals', 'icon': Icons.pending_actions_rounded, 'color': const Color(0xFFEF4444), 'screen': const AdminPendingFeesScreen()},
      {'title': 'Collect Fee', 'desc': 'Search & Pay', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF10B981), 'screen': const StudentFeeSearchScreen()},
      {'title': 'Receipts', 'desc': 'Print Invoices', 'icon': Icons.receipt_long_rounded, 'color': const Color(0xFF0EA5E9), 'screen': const FeeReceiptsScreen()},
      {'title': 'Reports', 'desc': 'Class Analytics', 'icon': Icons.analytics_rounded, 'color': const Color(0xFF6366F1), 'screen': Container()},
      {'title': 'Installments', 'desc': 'Timeline View', 'icon': Icons.history_rounded, 'color': const Color(0xFF8B5CF6), 'screen': const FeeInstallmentReportScreen()},
      {'title': 'Fee Structure', 'desc': 'Manage Templates', 'icon': Icons.account_tree_rounded, 'color': const Color(0xFFF59E0B), 'screen': const FeeStructureManagementScreen()},
      {'title': 'Payment Setup', 'desc': 'Bank & QR Code', 'icon': Icons.qr_code_2_rounded, 'color': const Color(0xFF64748B), 'screen': const AdminPaymentSettingsScreen()},
      {'title': 'Fee Category', 'desc': 'Add Custom Fee', 'icon': Icons.category_rounded, 'color': const Color(0xFFEC4899), 'screen': const AddStudentFeeScreen()},
      {'title': 'Transactions', 'desc': 'Payments List', 'icon': Icons.sync_alt_rounded, 'color': const Color(0xFF14B8A6), 'screen': const TransactionsScreen()},
      {'title': 'Fee Details', 'desc': 'Export & Share', 'icon': Icons.table_chart_rounded, 'color': const Color(0xFF3B82F6), 'screen': const StudentFeeDetailsScreen()},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05, // Much shorter cards so they fit perfectly
      ),
      itemBuilder: (context, index) {
        final mod = modules[index];
        return _buildGridModule(
          title: mod['title'] as String,
          desc: mod['desc'] as String,
          icon: mod['icon'] as IconData,
          color: mod['color'] as Color,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => mod['screen'] as Widget)),
        );
      },
    );
  }

  Widget _buildGridModule({required String title, required String desc, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: color.withOpacity(0.1),
      highlightColor: color.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF1E293B))),
            const SizedBox(height: 0),
            Text(desc, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 8, color: const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}
