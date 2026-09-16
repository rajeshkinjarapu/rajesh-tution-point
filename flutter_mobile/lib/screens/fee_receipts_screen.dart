import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FeeReceiptsScreen extends StatefulWidget {
  const FeeReceiptsScreen({super.key});

  @override
  State<FeeReceiptsScreen> createState() => _FeeReceiptsScreenState();
}

class _FeeReceiptsScreenState extends State<FeeReceiptsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _payments = [];
  List<dynamic> _filteredPayments = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPayments();
    _searchCtrl.addListener(_filterPayments);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getFeePayments();
      if (res['success']) {
        final List<dynamic> allPayments = res['data'] ?? [];
        final paid = allPayments.where((p) => p['status'] == 'PAID').toList();
        // Sort by date descending
        paid.sort((a, b) {
          final da = DateTime.tryParse(a['paymentDate'] ?? a['createdAt'] ?? '') ?? DateTime.now();
          final db = DateTime.tryParse(b['paymentDate'] ?? b['createdAt'] ?? '') ?? DateTime.now();
          return db.compareTo(da);
        });

        if (mounted) {
          setState(() {
            _payments = paid;
            _filteredPayments = paid;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = res['message'] ?? 'Failed to load receipts';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterPayments() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredPayments = _payments.where((p) {
        final studentName = (p['student']?['user']?['name'] ?? '').toString().toLowerCase();
        final receiptNo = (p['receiptNo'] ?? '').toString().toLowerCase();
        return studentName.contains(query) || receiptNo.contains(query);
      }).toList();
    });
  }

  Future<void> _generateReceiptPdf(Map<String, dynamic> payment) async {
    final pdf = pw.Document();
    final fmt = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0, locale: 'en_IN');
    final amount = double.tryParse(payment['amountPaid']?.toString() ?? '0') ?? 0.0;
    final date = DateTime.tryParse(payment['paymentDate'] ?? payment['createdAt'] ?? '') ?? DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Rajesh Tution Point', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                    pw.Text('123 Education Street, Knowledge City, State 400001', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(), bottom: pw.BorderSide())
                      ),
                      child: pw.Text('OFFICIAL FEE RECEIPT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Student Name:', style: const pw.TextStyle(color: PdfColors.grey600)),
                      pw.Text(payment['student']?['user']?['name'] ?? 'N/A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.SizedBox(height: 8),
                      pw.Text('Roll Number:', style: const pw.TextStyle(color: PdfColors.grey600)),
                      pw.Text(payment['student']?['rollNo'] ?? 'N/A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Receipt No:', style: const pw.TextStyle(color: PdfColors.grey600)),
                      pw.Text('#${(payment['receiptNo'] ?? '').toString().length > 16 ? payment['receiptNo'].toString().substring(0, 16) : payment['receiptNo']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.SizedBox(height: 8),
                      pw.Text('Payment Date:', style: const pw.TextStyle(color: PdfColors.grey600)),
                      pw.Text(dateStr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount Paid', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ]
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(payment['feeStructure']?['name'] ?? 'Fees')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(fmt.format(amount), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ]
                  ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey50),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(fmt.format(amount), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700))),
                    ]
                  )
                ]
              ),
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Payment Mode:', style: const pw.TextStyle(color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(color: PdfColors.indigo50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                        child: pw.Text(payment['paymentMethod'] ?? 'CASH', style: pw.TextStyle(color: PdfColors.indigo700, fontWeight: pw.FontWeight.bold)),
                      )
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Receiver Signature', style: const pw.TextStyle(color: PdfColors.grey600)),
                      pw.SizedBox(height: 40),
                      pw.Container(width: 120, height: 1, color: PdfColors.grey400),
                    ]
                  )
                ]
              )
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${payment['receiptNo']}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Payment Receipts', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF0EA5E9),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by student name or receipt no...',
                hintStyle: GoogleFonts.poppins(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : _filteredPayments.isEmpty
                        ? Center(child: Text('No receipts found', style: GoogleFonts.poppins(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredPayments.length,
                            itemBuilder: (context, index) {
                              final p = _filteredPayments[index];
                              return _buildReceiptCard(p);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> p) {
    final amount = double.tryParse(p['amountPaid']?.toString() ?? '0') ?? 0.0;
    final date = DateTime.tryParse(p['paymentDate'] ?? p['createdAt'] ?? '') ?? DateTime.now();
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0EA5E9)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receipt #${(p['receiptNo'] ?? '').toString().length > 8 ? (p['receiptNo'] ?? '').toString().substring(0,8) : p['receiptNo']}', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(p['student']?['user']?['name'] ?? 'Unknown', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(p['feeStructure']?['name'] ?? 'Fees', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmt.format(amount), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF0EA5E9))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('PAID', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(DateFormat('dd MMM yyyy').format(date), style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ),
              InkWell(
                onTap: () => _generateReceiptPdf(p),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.print_rounded, size: 16, color: Color(0xFF0EA5E9)),
                      const SizedBox(width: 4),
                      Text('Print', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0EA5E9))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
