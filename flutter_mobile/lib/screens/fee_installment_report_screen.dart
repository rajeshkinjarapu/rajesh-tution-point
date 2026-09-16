import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class FeeInstallmentReportScreen extends StatefulWidget {
  const FeeInstallmentReportScreen({super.key});

  @override
  State<FeeInstallmentReportScreen> createState() => _FeeInstallmentReportScreenState();
}

class _FeeInstallmentReportScreenState extends State<FeeInstallmentReportScreen> {
  bool _loading = true;
  List<dynamic> _students = [];
  List<dynamic> _structures = [];
  List<dynamic> _payments = [];
  List<dynamic> _classes = [];
  List<dynamic> _filtered = [];

  String _selectedClassId = 'ALL';
  String _paymentFilter = 'all'; // all, zero, partial, full
  String _search = '';

  final _currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getAllStudents(),
      ApiService.getFeeStructures(),
      ApiService.getFeePayments(),
      ApiService.getClasses(),
    ]);
    if (mounted) {
      setState(() {
        _students   = results[0]['success'] ? (results[0]['data'] ?? []) : [];
        _structures = results[1]['success'] ? (results[1]['data'] ?? []) : [];
        _payments   = results[2]['success'] ? (results[2]['data'] ?? []) : [];
        _classes    = results[3]['success'] ? (results[3]['data'] ?? []) : [];
        _loading = false;
        _buildReport();
      });
    }
  }

  void _buildReport() {
    // Compute per-student totals
    final Map<String, Map<String, dynamic>> studentMap = {};

    for (final s in _students) {
      final id = s['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      
      final user = s['user'] ?? {};
      String name = user['name']?.toString() ?? '';
      if (name.isEmpty) {
        name = '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
      }
      if (name.isEmpty) name = 'Unknown Student';
      
      final classId = s['class']?['id']?.toString() ?? '';
      final className = '${s['class']?['className'] ?? s['class']?['name'] ?? ''} ${s['class']?['section'] ?? ''}'.trim();

      // Total fee from structures for this student's class
      double totalFee = 0;
      for (final st in _structures) {
        final structClassId = st['class']?['id']?.toString() ?? st['classId']?.toString();
        final structStudentId = st['student']?['id']?.toString() ?? st['studentId']?.toString();
        if (structClassId == classId || structStudentId == id) {
          totalFee += double.tryParse(st['amount']?.toString() ?? '0') ?? 0;
        }
      }

      // Payments for this student
      final studentPayments = _payments.where((p) => p['student']?['id']?.toString() == id || p['studentId']?.toString() == id).toList();
      double totalPaid = 0;
      for (final p in studentPayments) {
        totalPaid += double.tryParse(p['amountPaid']?.toString() ?? '0') ?? 0;
      }

      studentMap[id] = {
        'id': id,
        'name': name,
        'classId': classId,
        'className': className,
        'totalFee': totalFee,
        'totalPaid': totalPaid,
        'balance': totalFee - totalPaid,
        'payments': studentPayments,
      };
    }

    var list = studentMap.values.toList();

    // Class filter
    if (_selectedClassId != 'ALL') {
      list = list.where((s) => s['classId'] == _selectedClassId).toList();
    }

    // Payment filter
    if (_paymentFilter == 'zero') {
      list = list.where((s) => (s['totalPaid'] as double) == 0).toList();
    } else if (_paymentFilter == 'partial') {
      list = list.where((s) {
        final paid = s['totalPaid'] as double;
        final total = s['totalFee'] as double;
        return paid > 0 && paid < total;
      }).toList();
    } else if (_paymentFilter == 'full') {
      list = list.where((s) {
        final paid = s['totalPaid'] as double;
        final total = s['totalFee'] as double;
        return total > 0 && paid >= total;
      }).toList();
    }

    // Search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((s) => (s['name'] as String).toLowerCase().contains(q)).toList();
    }

    // Sort by name
    list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    setState(() => _filtered = list);
  }

  @override
  Widget build(BuildContext context) {
    // Summary totals
    double totalFeeSum = 0, totalPaidSum = 0;
    for (final s in _filtered) {
      totalFeeSum += s['totalFee'] as double;
      totalPaidSum += s['totalPaid'] as double;
    }
    final totalBalance = totalFeeSum - totalPaidSum;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Payment Installment Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
          : Column(
              children: [
                // Summary bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      _summaryChip('Total', _currency.format(totalFeeSum), const Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      _summaryChip('Collected', _currency.format(totalPaidSum), const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _summaryChip('Due', _currency.format(totalBalance), const Color(0xFFEF4444)),
                    ],
                  ),
                ),
                // Filters
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      // Search
                      TextField(
                        onChanged: (v) { _search = v; _buildReport(); },
                        style: GoogleFonts.poppins(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search student name...',
                          hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                          filled: true, fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _filterDropdown<String>(
                          value: _selectedClassId,
                          items: [
                            const DropdownMenuItem(value: 'ALL', child: Text('All Classes')),
                            ..._classes.map((c) => DropdownMenuItem(
                              value: c['id']?.toString() ?? '',
                              child: Text('${c['name'] ?? c['className'] ?? ''} ${c['section'] ?? ''}'.trim()),
                            )),
                          ],
                          onChanged: (v) { setState(() => _selectedClassId = v ?? 'ALL'); _buildReport(); },
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: _filterDropdown<String>(
                          value: _paymentFilter,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Students')),
                            DropdownMenuItem(value: 'zero', child: Text('Not Paid')),
                            DropdownMenuItem(value: 'partial', child: Text('Partial')),
                            DropdownMenuItem(value: 'full', child: Text('Fully Paid')),
                          ],
                          onChanged: (v) { setState(() => _paymentFilter = v ?? 'all'); _buildReport(); },
                        )),
                      ]),
                    ],
                  ),
                ),
                // Count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFFF8FAFC),
                  child: Row(children: [
                    Text('${_filtered.length} students', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                  ]),
                ),
                // List
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.assignment_outlined, size: 60, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 12),
                          Text('No students found', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 16)),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) => _buildStudentCard(_filtered[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final name = student['name'] as String;
    final className = student['className'] as String;
    final totalFee = student['totalFee'] as double;
    final totalPaid = student['totalPaid'] as double;
    final balance = student['balance'] as double;
    final payments = student['payments'] as List<dynamic>;

    final isFullPaid = totalFee > 0 && totalPaid >= totalFee;
    final hasNoPayment = totalPaid == 0;

    Color statusColor = const Color(0xFFF59E0B);
    String statusLabel = 'PARTIAL';
    if (isFullPaid) { statusColor = const Color(0xFF10B981); statusLabel = 'PAID'; }
    if (hasNoPayment) { statusColor = const Color(0xFFEF4444); statusLabel = 'UNPAID'; }

    final pct = totalFee > 0 ? (totalPaid / totalFee).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: GoogleFonts.outfit(color: const Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B))),
            Text(className.isEmpty ? 'Unknown Class' : className, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(statusLabel, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
          ),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Paid: ${_currency.format(totalPaid)}', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
              Text('Due: ${_currency.format(balance)}', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444), fontWeight: FontWeight.w600)),
              Text('Total: ${_currency.format(totalFee)}', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
        children: [
          // Payment installments
          if (payments.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('No payment records', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: [
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Text('Payment Installments', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B))),
                const SizedBox(height: 8),
                ...payments.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final p = entry.value;
                  final amt = double.tryParse(p['amountPaid']?.toString() ?? '0') ?? 0;
                  final method = p['paymentMethod']?.toString() ?? p['method']?.toString() ?? 'CASH';
                  final date = p['paymentDate']?.toString() ?? p['createdAt']?.toString() ?? '';
                  final dateStr = date.isNotEmpty ? date.split('T')[0] : 'N/A';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withOpacity(0.15), shape: BoxShape.circle),
                        child: Center(child: Text('$idx', style: GoogleFonts.outfit(color: const Color(0xFF0EA5E9), fontWeight: FontWeight.bold, fontSize: 12))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_currency.format(amt), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0EA5E9))),
                        Text('$method  •  $dateStr', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8))),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                      ),
                    ]),
                  );
                }),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, color: color, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      ]),
    ));
  }

  Widget _filterDropdown<T>({required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value, items: items, onChanged: onChanged, isExpanded: true, isDense: true,
          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
        ),
      ),
    );
  }
}
