import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class StudentFeeDetailsScreen extends StatefulWidget {
  const StudentFeeDetailsScreen({super.key});

  @override
  State<StudentFeeDetailsScreen> createState() => _StudentFeeDetailsScreenState();
}

class _StudentFeeDetailsScreenState extends State<StudentFeeDetailsScreen> {
  bool _isLoading = true;
  List<dynamic> _students = [];
  List<dynamic> _classes = [];
  List<dynamic> _structures = [];
  List<dynamic> _payments = [];
  List<Map<String, dynamic>> _tableData = [];
  List<Map<String, dynamic>> _filteredData = [];

  String _selectedClassId = 'ALL';
  String _paymentFilter = 'all'; // all, zero, partial, full
  String _searchQuery = '';

  final _currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getAllStudents(),
        ApiService.getClasses(),
        ApiService.getFeeStructures(),
        ApiService.getFeePayments(),
      ]);

      if (mounted) {
        setState(() {
          _students = results[0]['success'] ? (results[0]['data'] ?? []) : [];
          _classes = results[1]['success'] ? (results[1]['data'] ?? []) : [];
          _structures = results[2]['success'] ? (results[2]['data'] ?? []) : [];
          _payments = results[3]['success'] ? (results[3]['data'] ?? []) : [];
          _computeData();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _computeData() {
    _tableData.clear();
    for (final s in _students) {
      final id = s['id']?.toString() ?? '';
      if (id.isEmpty) continue;

      final user = s['user'] ?? {};
      String name = user['name']?.toString() ?? '';
      if (name.isEmpty) {
        name = '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
      }
      if (name.isEmpty) name = 'Unknown Student';

      final classId = s['class']?['id']?.toString() ?? s['classId']?.toString() ?? '';
      final className = '${s['class']?['className'] ?? s['class']?['name'] ?? ''} ${s['class']?['section'] ?? ''}'.trim();
      final phone = user['phone']?.toString() ?? s['phone']?.toString() ?? '';

      double totalFee = 0;
      for (final st in _structures) {
        final structClassId = st['class']?['id']?.toString() ?? st['classId']?.toString();
        final structStudentId = st['student']?['id']?.toString() ?? st['studentId']?.toString();
        if (structClassId == classId || structStudentId == id) {
          totalFee += double.tryParse(st['amount']?.toString() ?? '0') ?? 0;
        }
      }

      double totalPaid = 0;
      final studentPayments = _payments.where((p) => p['student']?['id']?.toString() == id || p['studentId']?.toString() == id);
      for (final p in studentPayments) {
        final status = p['status']?.toString().toUpperCase() ?? '';
        if (status == 'PAID' || status == 'PARTIAL') {
          totalPaid += double.tryParse(p['amountPaid']?.toString() ?? '0') ?? 0;
        }
      }

      _tableData.add({
        'id': id,
        'studentId': s['rollNo']?.toString() ?? s['studentId']?.toString() ?? '-',
        'name': name,
        'classId': classId,
        'className': className.isEmpty ? '-' : className,
        'phone': phone,
        'totalFee': totalFee,
        'paidAmount': totalPaid,
        'balance': totalFee - totalPaid,
      });
    }

    _applyFilters();
  }

  void _applyFilters() {
    var temp = List<Map<String, dynamic>>.from(_tableData);

    if (_selectedClassId != 'ALL') {
      temp = temp.where((s) => s['classId'] == _selectedClassId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      temp = temp.where((s) => (s['name'] as String).toLowerCase().contains(q) || (s['studentId'] as String).toLowerCase().contains(q)).toList();
    }

    if (_paymentFilter == 'zero') {
      temp = temp.where((s) => (s['paidAmount'] as double) == 0).toList();
    } else if (_paymentFilter == 'partial') {
      temp = temp.where((s) {
        final p = s['paidAmount'] as double;
        final b = s['balance'] as double;
        return p > 0 && b > 0;
      }).toList();
    } else if (_paymentFilter == 'full') {
      temp = temp.where((s) {
        final b = s['balance'] as double;
        final t = s['totalFee'] as double;
        return b <= 0 && t > 0;
      }).toList();
    }

    temp.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    setState(() {
      _filteredData = temp;
    });
  }

  Future<void> _exportPdf() async {
    if (_filteredData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF...')));
    
    final pdf = pw.Document();

    final headers = ['S.No', 'Student ID', 'Name', 'Class', 'Total Fee', 'Paid', 'Balance'];
    
    final data = _filteredData.asMap().entries.map((entry) {
      final i = entry.key;
      final r = entry.value;
      return [
        (i + 1).toString(),
        r['studentId'].toString(),
        r['name'].toString(),
        r['className'].toString(),
        r['totalFee'].toString(),
        r['paidAmount'].toString(),
        r['balance'].toString(),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Center(child: pw.Text('Rajesh Tution Point', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text('Opp. Hero Showroom, SVL Paradise Campus, Narasannapeta', style: const pw.TextStyle(fontSize: 9))),
            pw.SizedBox(height: 12),
            pw.Center(child: pw.Text('STUDENT FEE DETAILS REPORT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Students: ${_filteredData.length}'),
                pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}'),
              ]
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Fee_Details_Report.pdf');
      await file.writeAsBytes(await pdf.save());
      
      await Share.shareXFiles([XFile(file.path)], text: 'Fee Details Report');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
    }
  }

  Future<void> _exportCsv() async {
    if (_filteredData.isEmpty) return;
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating CSV...')));
    
    StringBuffer csv = StringBuffer();
    csv.writeln('S.No,Student ID,Name,Class,Phone,Total Fee,Paid,Balance');
    
    for (int i = 0; i < _filteredData.length; i++) {
      final r = _filteredData[i];
      csv.writeln('${i + 1},"${r['studentId']}","${r['name']}","${r['className']}","${r['phone']}",${r['totalFee']},${r['paidAmount']},${r['balance']}');
    }
    
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Fee_Details_Report.csv');
      await file.writeAsString(csv.toString());
      
      await Share.shareXFiles([XFile(file.path)], text: 'Fee Details Report (CSV)');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting CSV: $e')));
    }
  }

  void _sendWhatsAppReminder(Map<String, dynamic> student) async {
    String phone = student['phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number registered for this student.')));
      return;
    }
    if (phone.length == 10) phone = '91$phone';

    final text = 'Dear Parent of *${student['name']}*,\nThis is a fee reminder from *Rajesh Tution Point*.\n\n'
                 'Total Fee: ${_currency.format(student['totalFee'])}\n'
                 'Paid: ${_currency.format(student['paidAmount'])}\n'
                 'Balance Due: *${_currency.format(student['balance'])}*\n\n'
                 'Kindly clear the dues at the earliest. Ignore if already paid.';
                 
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Student Fee Details', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3B82F6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download, color: Colors.white),
            onSelected: (val) {
              if (val == 'pdf') _exportPdf();
              if (val == 'csv') _exportCsv();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
              const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : Column(
              children: [
                // Filters
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedClassId,
                              decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder(), isDense: true),
                              items: [
                                const DropdownMenuItem(value: 'ALL', child: Text('All Classes')),
                                ..._classes.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text('${c['className'] ?? c['name'] ?? ''} ${c['section'] ?? ''}'.trim()))),
                              ],
                              onChanged: (v) { setState(() => _selectedClassId = v ?? 'ALL'); _applyFilters(); },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _paymentFilter,
                              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Students')),
                                DropdownMenuItem(value: 'zero', child: Text('No Payment')),
                                DropdownMenuItem(value: 'partial', child: Text('Partial Paid')),
                                DropdownMenuItem(value: 'full', child: Text('Fully Paid')),
                              ],
                              onChanged: (v) { setState(() => _paymentFilter = v ?? 'all'); _applyFilters(); },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Search student...', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.search)),
                        onChanged: (v) { setState(() => _searchQuery = v); _applyFilters(); },
                      ),
                    ],
                  ),
                ),
                
                // List
                Expanded(
                  child: _filteredData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.group_off, size: 60, color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 16),
                              Text('No students match criteria', style: GoogleFonts.outfit(fontSize: 18, color: const Color(0xFF94A3B8))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredData.length,
                          itemBuilder: (ctx, i) {
                            final st = _filteredData[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFFEEF2FF),
                                        child: Text(st['name'].toString().isNotEmpty ? st['name'].toString()[0].toUpperCase() : 'S', style: GoogleFonts.outfit(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(st['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B))),
                                            Text(st['className'], style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
                                            if (st['phone'].toString().isNotEmpty)
                                              Text(st['phone'], style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8))),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.message_rounded, color: Color(0xFF25D366)),
                                        tooltip: 'WhatsApp Reminder',
                                        onPressed: () => _sendWhatsAppReminder(st),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Total Fee', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8))),
                                          Text(_currency.format(st['totalFee']), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B))),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text('Paid', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8))),
                                          Text(_currency.format(st['paidAmount']), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF10B981))),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('Balance', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8))),
                                          Text(_currency.format(st['balance']), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFFEF4444))),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
    );
  }
}
