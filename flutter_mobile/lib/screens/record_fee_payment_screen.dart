import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class RecordFeePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final double pendingAmount;
  final List<dynamic> structures;

  const RecordFeePaymentScreen({
    super.key,
    required this.student,
    required this.pendingAmount,
    required this.structures,
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

  final List<Map<String, dynamic>> _methods = [
    {'id': 'CASH', 'label': 'Cash', 'icon': Icons.money_rounded, 'color': const Color(0xFF10B981)},
    {'id': 'UPI', 'label': 'UPI / Scan', 'icon': Icons.qr_code_scanner_rounded, 'color': const Color(0xFF8B5CF6)},
    {'id': 'BANK_TRANSFER', 'label': 'Bank Txn', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFF0EA5E9)},
  ];

  @override
  void initState() {
    super.initState();
    for (final st in widget.structures) {
      final id = st['id'] as String;
      _checked[id] = false;
      _amountControllers[id] = TextEditingController(text: (st['amount'] ?? 0).toString());
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

  double get _totalAmount {
    double total = 0;
    for (final st in widget.structures) {
      final id = st['id'] as String;
      if (_checked[id] == true) {
        total += double.tryParse(_amountControllers[id]?.text ?? '0') ?? 0;
      }
    }
    return total;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    final selected = widget.structures.where((st) => _checked[st['id']] == true).toList();
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
    
    // Construct the payload for the backend
    final Map<String, dynamic> payload = {
      'studentId': studentId,
      'method': _method,
      'paymentDate': _paymentDate.toIso8601String().split('T')[0],
      'remarks': _remarksCtrl.text,
      'payments': selected.map((st) {
        final amt = double.tryParse(_amountControllers[st['id']]?.text ?? '0') ?? 0;
        return {
          'feeStructureId': st['id'],
          'amountPaid': amt,
        };
      }).toList(),
    };

    final result = await ApiService.recordPayments(payload);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result['success']) {
        _showSuccessReceipt();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Payment failed'),
          backgroundColor: const Color(0xFFF43F5E),
        ));
      }
    }
  }

  void _showSuccessReceipt() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildReceiptBottomSheet(),
    ).then((_) => Navigator.pop(context, true));
  }

  Widget _buildReceiptBottomSheet() {
    final user = widget.student['user'] ?? {};
    final name = user['name'] ?? '${widget.student['firstName']} ${widget.student['lastName']}';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 80),
            const SizedBox(height: 16),
            Text('Payment Successful!', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text('₹${_totalAmount.toStringAsFixed(0)} has been recorded for $name.', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  _buildReceiptRow('Receipt Date', DateFormat('MMM dd, yyyy').format(DateTime.now())),
                  _buildReceiptRow('Payment Method', _method),
                  _buildReceiptRow('Transaction ID', 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.print_rounded),
                label: Text('Print Receipt (PDF)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Record Payment', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudentInfoCard(),
                  Text('Payment Date', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(_paymentDate),
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                          ),
                          const Icon(Icons.calendar_month_rounded, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentMethods(),
                  const SizedBox(height: 16),
                  Text('Fee Components', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  _buildStructuresList(),
                  const SizedBox(height: 16),
                  Text('Remarks / Notes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  _buildRemarksField(),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Paying', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                  Text('₹${_totalAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                ],
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Confirm Pay', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    final user = widget.student['user'] ?? {};
    final name = user['name'] ?? '${widget.student['firstName']} ${widget.student['lastName']}';
    final rollNo = widget.student['rollNo'] ?? '-';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF4F46E5),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                Text('Roll No: $rollNo', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        const SizedBox(height: 8),
        Row(
          children: _methods.map((m) {
            final isSelected = _method == m['id'];
            final color = m['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _method = m['id']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    children: [
                      Icon(m['icon'], color: isSelected ? color : const Color(0xFF64748B)),
                      const SizedBox(height: 8),
                      Text(
                        m['label'],
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? color : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStructuresList() {
    if (widget.structures.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 48),
            const SizedBox(height: 16),
            Text('No pending fees found.', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.structures.length,
      itemBuilder: (context, index) {
        final st = widget.structures[index];
        final id = st['id'] as String;
        final isChecked = _checked[id] ?? false;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isChecked ? const Color(0xFFEEF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isChecked ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0), width: isChecked ? 2 : 1),
            boxShadow: isChecked ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))] : [],
          ),
          child: Column(
            children: [
              CheckboxListTile(
                value: isChecked,
                onChanged: (val) {
                  setState(() => _checked[id] = val ?? false);
                },
                activeColor: const Color(0xFF6366F1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(st['name'] ?? 'Fee Component', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), fontSize: 16)),
                subtitle: isChecked ? null : Text('Total: ₹${st['amount']}', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13)),
              ),
              if (isChecked)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _amountControllers[id],
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      labelText: 'Amount Paying',
                      labelStyle: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                      prefixText: '₹ ',
                      prefixStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemarksField() {
    return TextField(
      controller: _remarksCtrl,
      maxLines: 2,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: 'Add remarks, cheque no, UTR etc. (Optional)',
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
      ),
    );
  }
}
