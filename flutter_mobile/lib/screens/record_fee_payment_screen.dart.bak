import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class RecordFeePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final List<dynamic> feeStructures;
  final List<dynamic> payments;
  final List<dynamic> discounts;

  const RecordFeePaymentScreen({
    super.key,
    required this.student,
    required this.feeStructures,
    required this.payments,
    required this.discounts,
  });

  @override
  State<RecordFeePaymentScreen> createState() => _RecordFeePaymentScreenState();
}

class _RecordFeePaymentScreenState extends State<RecordFeePaymentScreen> {
  final Map<String, bool> _checked = {};
  final Map<String, TextEditingController> _amountControllers = {};
  String _method = 'CASH';
  final TextEditingController _remarksCtrl = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  bool _isSubmitting = false;

  late List<dynamic> _availableStructures;

  final List<String> _methods = ['CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE'];
  final Map<String, Color> _methodColors = {
    'CASH': const Color(0xFF10B981),
    'UPI': const Color(0xFF8B5CF6),
    'BANK_TRANSFER': const Color(0xFF0EA5E9),
    'CHEQUE': const Color(0xFFF59E0B),
  };
  final Map<String, IconData> _methodIcons = {
    'CASH': Icons.money_rounded,
    'UPI': Icons.qr_code_scanner_rounded,
    'BANK_TRANSFER': Icons.account_balance_rounded,
    'CHEQUE': Icons.receipt_long_rounded,
  };

  @override
  void initState() {
    super.initState();
    _calculateAvailable();
    for (final st in _availableStructures) {
      final id = st['id'] as String;
      _checked[id] = false;
      final pending = _getPending(st);
      _amountControllers[id] = TextEditingController(text: pending > 0 ? pending.toStringAsFixed(0) : '0');
    }
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _calculateAvailable() {
    final studentId = widget.student['id'];
    final classId = widget.student['classId'];
    _availableStructures = widget.feeStructures
        .where((s) => s['studentId'] == studentId || s['classId'] == classId)
        .toList();
  }

  double _getPending(dynamic structure) {
    double paid = 0.0;
    for (final p in widget.payments) {
      if (p['feeStructureId'] == structure['id']) {
        paid += (p['amountPaid'] ?? 0.0).toDouble();
      }
    }
    double disc = 0.0;
    for (final d in widget.discounts) {
      if (d['feeStructureId'] == structure['id']) {
        disc += (d['amount'] ?? 0.0).toDouble();
      }
    }
    return ((structure['amount'] ?? 0.0).toDouble() - disc - paid).clamp(0, double.infinity);
  }

  double get _totalAmount {
    double total = 0;
    for (final st in _availableStructures) {
      final id = st['id'] as String;
      if (_checked[id] == true) {
        total += double.tryParse(_amountControllers[id]?.text ?? '0') ?? 0;
      }
    }
    return total;
  }

  Future<void> _submit() async {
    final selected = _availableStructures.where((st) => _checked[st['id']] == true).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one fee component'), backgroundColor: Color(0xFFF43F5E)));
      return;
    }
    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount'), backgroundColor: Color(0xFFF43F5E)));
      return;
    }

    setState(() => _isSubmitting = true);

    final studentId = widget.student['id'];
    final payments = selected.map((st) {
      final amt = double.tryParse(_amountControllers[st['id']]?.text ?? '0') ?? 0;
      return {
        'studentId': studentId,
        'feeStructureId': st['id'],
        'amountPaid': amt,
        'method': _method,
        'paymentDate': _paymentDate.toIso8601String().split('T')[0],
        'remarks': _remarksCtrl.text,
      };
    }).toList();

    final result = await ApiService.recordPayments(payments);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment of ₹${_totalAmount.toStringAsFixed(0)} recorded!'),
          backgroundColor: const Color(0xFF10B981),
        ));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Payment failed'),
          backgroundColor: const Color(0xFFF43F5E),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.student['user'] ?? {};
    final name = '${widget.student['firstName'] ?? ''} ${widget.student['lastName'] ?? ''}'.trim().isNotEmpty 
                 ? '${widget.student['firstName'] ?? ''} ${widget.student['lastName'] ?? ''}'.trim() 
                 : (user['name'] ?? 'Student');
    final photoUrl = user['photoUrl'];
    final className = '${widget.student['class']?['name'] ?? ''} - ${widget.student['class']?['section'] ?? ''}'.trim();
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Process Payment', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
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
      ),
      body: Column(
        children: [
          // Premium Gradient Student Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
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
              children: [
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
                    child: (photoUrl != null && photoUrl.toString().isNotEmpty)
                        ? Image.network(
                            ApiService.getImageUrl(photoUrl.toString()),
                            fit: BoxFit.cover,
                            headers: const {'ngrok-skip-browser-warning': '69420'},
                            errorBuilder: (c, e, s) => _photoFallback(name),
                          )
                        : _photoFallback(name),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (className.isNotEmpty && className != ' - ')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                className,
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
                              'Adm: ${widget.student['admissionNumber'] ?? widget.student['rollNo'] ?? 'N/A'}',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('1', 'Select Fees', gradientStart: const Color(0xFF3B82F6), gradientEnd: const Color(0xFF2563EB)),
                  const SizedBox(height: 16),
                  if (_availableStructures.isEmpty)
                    _emptyCard('No fee components assigned to this student.')
                  else
                    ..._availableStructures.map((st) {
                      final id = st['id'] as String;
                      final isChecked = _checked[id] == true;
                      final pending = _getPending(st);
                      final total = (st['amount'] ?? 0.0).toDouble();
                      final headName = st['head'] != null ? st['head']['name'] : (st['name'] ?? 'Fee');
                      
                      if (pending <= 0) return const SizedBox.shrink(); // Hide fully paid structures

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isChecked ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0), width: isChecked ? 2 : 1),
                          boxShadow: isChecked ? [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => setState(() => _checked[id] = !isChecked),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: isChecked ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isChecked ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1), width: 1.5),
                                        ),
                                        child: isChecked ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(headName, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                            const SizedBox(height: 2),
                                            Text('Pending: ${currencyFormat.format(pending)}', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFF43F5E), fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isChecked) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Row(
                                        children: [
                                          Text('Pay', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                                          const SizedBox(width: 12),
                                          const Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: TextField(
                                              controller: _amountControllers[id],
                                              keyboardType: TextInputType.number,
                                              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8)),
                                              textAlign: TextAlign.right,
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 32),
                  _sectionHeader('2', 'Transaction Details', gradientStart: const Color(0xFF8B5CF6), gradientEnd: const Color(0xFF6D28D9)),
                  const SizedBox(height: 16),

                  // Payment Date
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DATE OF PAYMENT', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _paymentDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (ctx, child) => Theme(
                                data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF6366F1))),
                                child: child!,
                              ),
                            );
                            if (picked != null) setState(() => _paymentDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: Color(0xFF6366F1), size: 20),
                                const SizedBox(width: 12),
                                Text(DateFormat('dd MMM yyyy').format(_paymentDate), style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                                const Spacer(),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payment Method
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PAYMENT METHOD', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 3.0,
                          children: _methods.map((m) {
                            final isSelected = _method == m;
                            final color = _methodColors[m] ?? const Color(0xFF6366F1);
                            final icon = _methodIcons[m] ?? Icons.payment;
                            final displayMap = {'CASH': 'Cash', 'UPI': 'UPI', 'BANK_TRANSFER': 'Bank Tr.', 'CHEQUE': 'Cheque'};

                            return GestureDetector(
                              onTap: () => setState(() => _method = m),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? color.withOpacity(0.1) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
                                  boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))] : [],
                                ),
                                child: Row(
                                  children: [
                                    Icon(icon, color: isSelected ? color : const Color(0xFF94A3B8), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(displayMap[m]!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? color : const Color(0xFF64748B)))),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Remarks
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REMARKS (OPTIONAL)', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _remarksCtrl,
                        maxLines: 2,
                        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          hintText: 'Add UTR, Cheque No, or notes...',
                          hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(currencyFormat),
    );
  }

  Widget _buildBottomBar(NumberFormat format) {
    final total = _totalAmount;
    final hasSelected = _checked.values.any((v) => v);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 12),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Amount', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
                Text(format.format(total), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: (_isSubmitting || !hasSelected || total <= 0) ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: (hasSelected && total > 0) ? [const Color(0xFF10B981), const Color(0xFF059669)] : [const Color(0xFFCBD5E1), const Color(0xFF94A3B8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: (hasSelected && total > 0) ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text('Confirm Pay', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String step, String title, {Color gradientStart = const Color(0xFF6366F1), Color gradientEnd = const Color(0xFF4F46E5)}) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: gradientStart.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Center(child: Text(step, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        ),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _photoFallback(String name) {
    return Container(
      color: const Color(0xFFEEF2FF),
      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: GoogleFonts.outfit(color: const Color(0xFF6366F1), fontSize: 24, fontWeight: FontWeight.bold))),
    );
  }

  Widget _badge(String text, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0), width: 1, style: BorderStyle.solid)),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 48),
            const SizedBox(height: 16),
            Text(msg, style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
