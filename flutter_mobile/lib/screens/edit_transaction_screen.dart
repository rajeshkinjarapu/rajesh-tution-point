import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class EditTransactionScreen extends StatefulWidget {
  final dynamic transaction;
  const EditTransactionScreen({Key? key, required this.transaction}) : super(key: key);

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TextEditingController _amountC;
  late TextEditingController _remarksC;
  late String _selectedMethod;
  DateTime _paymentDate = DateTime.now();
  bool _isSaving = false;

  final List<String> _methods = ['CASH', 'UPI', 'CHEQUE', 'NEFT', 'RTGS', 'CARD'];

  @override
  void initState() {
    super.initState();
    _amountC = TextEditingController(text: widget.transaction['amountPaid']?.toString() ?? '');
    _remarksC = TextEditingController(text: widget.transaction['remarks'] ?? '');
    _selectedMethod = widget.transaction['method'] ?? widget.transaction['paymentMethod'] ?? 'CASH';
    
    if (widget.transaction['paymentDate'] != null) {
      try {
        _paymentDate = DateTime.parse(widget.transaction['paymentDate'].toString());
      } catch (e) {
        _paymentDate = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _amountC.dispose();
    _remarksC.dispose();
    super.dispose();
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

  Future<void> _saveChanges() async {
    final amt = double.tryParse(_amountC.text);
    if (amt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
      return;
    }

    setState(() => _isSaving = true);
    
    final payload = {
      'amountPaid': amt,
      'method': _selectedMethod,
      'remarks': _remarksC.text,
      'paymentDate': _paymentDate.toIso8601String(),
    };

    final res = await ApiService.updateFeePayment(widget.transaction['id']?.toString() ?? '', payload);
    
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] ? 'Transaction updated!' : (res['message'] ?? 'Failed')),
          backgroundColor: res['success'] ? const Color(0xFF10B981) : const Color(0xFFF43F5E)
        )
      );
      if (res['success']) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: Text('Edit Transaction', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount Paid', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            const SizedBox(height: 8),
            TextField(
              controller: _amountC,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.outfit(fontSize: 24, color: const Color(0xFF10B981)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Payment Date', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(_paymentDate),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                    ),
                    const Icon(Icons.calendar_month_rounded, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Payment Method', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _methods.map((m) => GestureDetector(
                onTap: () => setState(() => _selectedMethod = m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedMethod == m ? const Color(0xFF6366F1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedMethod == m ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    m,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedMethod == m ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),

            Text('Remarks / Notes', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            const SizedBox(height: 8),
            TextField(
              controller: _remarksC,
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'UTR, cheque no, or other notes...',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: const Color(0xFF4F46E5).withOpacity(0.4),
            ),
            child: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Save Changes', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
