import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

import 'staff_attendance_report_screen.dart';
import 'results_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<dynamic> _classes = [];
  List<dynamic> _exams = [];
  bool _loading = true;

  // Filter state
  String? _attendanceClassId;
  String? _marksClassId;
  String? _marksExamId;
  String? _studentClassId;

  @override
  void initState() {
    super.initState();
    _fetchFilters();
  }

  Future<void> _fetchFilters() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getClasses(),
      ApiService.getExams(),
    ]);
    if (mounted) {
      setState(() {
        _classes = results[0]['success'] ? (results[0]['data'] ?? []) : [];
        _exams   = results[1]['success'] ? (results[1]['data'] ?? []) : [];
        _loading = false;
      });
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.download_done_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _downloadReport(String endpoint, String filename) {
    // On mobile, we open the URL in the browser via ApiService base URL
    _showMsg('Report request sent! Open in browser to download.');
    // In a real implementation, we'd use url_launcher to open the API endpoint
    // url_launcher: await launchUrl(Uri.parse('${ApiService.baseUrl}$endpoint'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      drawer: const AppDrawer(currentRoute: 'reports'),
      appBar: AppBar(
        title: Text('Reports Generator', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header banner
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.3), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF6366F1), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Reports Generator', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          Text('Download Excel & PDF reports', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        ]),
                      ),
                    ],
                  ),
                ),

                // Attendance Report
                _buildReportCard(
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFF0D9488),
                  iconBg: const Color(0xFFF0FDFA),
                  title: 'ATTENDANCE LEDGER',
                  description: 'Class aggregate present, absent, and late rates report.',
                  filterWidget: _buildClassDropdown(
                    value: _attendanceClassId,
                    onChanged: (v) => setState(() => _attendanceClassId = v),
                    hint: 'All Classes',
                  ),
                  onExcel: () => _downloadReport(
                    '/api/reports/attendance?classId=${_attendanceClassId ?? ''}',
                    'Attendance_Report.xlsx',
                  ),
                  onPdf: () => _downloadReport(
                    '/api/reports/attendance/pdf?classId=${_attendanceClassId ?? ''}',
                    'Attendance_Report.pdf',
                  ),
                  excelEnabled: true,
                  pdfEnabled: true,
                ),

                const SizedBox(height: 14),

                // Marks Report
                _buildReportCard(
                  icon: Icons.assignment_turned_in_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFFFBEB),
                  title: 'GRADES SHEET',
                  description: 'Class assessment scores, total ranks, grades and statistics.',
                  filterWidget: Column(
                    children: [
                      _buildClassDropdown(
                        value: _marksClassId,
                        onChanged: (v) => setState(() => _marksClassId = v),
                        hint: 'Select Class',
                      ),
                      const SizedBox(height: 8),
                      _buildExamDropdown(),
                    ],
                  ),
                  onExcel: (_marksClassId != null && _marksExamId != null)
                      ? () => _downloadReport('/api/reports/marks?classId=$_marksClassId&examId=$_marksExamId', 'Marks_Report.xlsx')
                      : null,
                  onPdf: (_marksClassId != null && _marksExamId != null)
                      ? () => _downloadReport('/api/reports/marks/pdf?classId=$_marksClassId&examId=$_marksExamId', 'Marks_Report.pdf')
                      : null,
                  excelEnabled: _marksClassId != null && _marksExamId != null,
                  pdfEnabled: _marksClassId != null && _marksExamId != null,
                ),

                const SizedBox(height: 14),

                _buildReportCard(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  iconBg: const Color(0xFFEEF2FF),
                  title: 'FEES TRANSACTION HISTORY',
                  description: 'Total revenue statements, payment modes, terms, and due dates.',
                  onExcel: () => _downloadReport('/api/reports/fees', 'Fee_Report.xlsx'),
                  onPdf: () => _downloadReport('/api/reports/fees/pdf', 'Fee_Report.pdf'),
                  excelEnabled: true,
                  pdfEnabled: true,
                ),

                const SizedBox(height: 14),

                _buildReportCard(
                  icon: Icons.people_alt_rounded,
                  iconColor: const Color(0xFF0D9488),
                  iconBg: const Color(0xFFF0FDFA),
                  title: 'STUDENTS ROSTER',
                  description: 'Comprehensive directory list of student profiles.',
                  filterWidget: _buildClassDropdown(
                    value: _studentClassId,
                    onChanged: (v) => setState(() => _studentClassId = v),
                    hint: 'All Classes',
                  ),
                  onExcel: () => _downloadReport('/api/reports/students?classId=${_studentClassId ?? ''}', 'Student_Report.xlsx'),
                  onPdf: () => _downloadReport('/api/reports/students/pdf?classId=${_studentClassId ?? ''}', 'Student_Report.pdf'),
                  excelEnabled: true,
                  pdfEnabled: true,
                ),

                const SizedBox(height: 24),

                Text('Advanced Analytics', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B))),
                const SizedBox(height: 12),

                _buildReportCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  iconBg: const Color(0xFFF3E8FF),
                  title: 'FEE COLLECTION FORECASTING',
                  description: 'Cash flow analytics, collections vs outstanding dues, and monthly projections.',
                  onExcel: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Container())),
                  excelIcon: Icons.arrow_forward_ios_rounded,
                  excelLabel: 'View',
                  excelEnabled: true,
                ),
                const SizedBox(height: 14),

                _buildReportCard(
                  icon: Icons.person_pin_rounded,
                  iconColor: const Color(0xFFEA580C),
                  iconBg: const Color(0xFFFFEDD5),
                  title: 'STAFF ATTENDANCE LEDGER',
                  description: 'Monthly staff attendance ledger with aggregate work days, leaves, and late records.',
                  onExcel: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Container())),
                  excelIcon: Icons.arrow_forward_ios_rounded,
                  excelLabel: 'View',
                  excelEnabled: true,
                ),
                const SizedBox(height: 14),

                _buildReportCard(
                  icon: Icons.bar_chart_rounded,
                  iconColor: const Color(0xFFE11D48),
                  iconBg: const Color(0xFFFFE4E6),
                  title: 'COMPARATIVE CLASS PERFORMANCE',
                  description: 'Detailed comparative graph and report to analyze subject metrics across classes.',
                  onExcel: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultsScreen())),
                  excelIcon: Icons.arrow_forward_ios_rounded,
                  excelLabel: 'View',
                  excelEnabled: true,
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
    Widget? filterWidget,
    VoidCallback? onExcel,
    VoidCallback? onPdf,
    bool excelEnabled = false,
    bool pdfEnabled = false,
    IconData excelIcon = Icons.table_chart_rounded,
    String excelLabel = 'Excel',
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B), letterSpacing: 0.3)),
                    Text(description, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],
            ),
            if (filterWidget != null) ...[const SizedBox(height: 14), filterWidget],
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: excelEnabled ? onExcel : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: excelEnabled ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: excelEnabled ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(excelIcon, size: 15, color: excelEnabled ? const Color(0xFF10B981) : const Color(0xFFCBD5E1)),
                        const SizedBox(width: 6),
                        Text(excelLabel, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: excelEnabled ? const Color(0xFF10B981) : const Color(0xFFCBD5E1))),
                      ]),
                    ),
                  ),
                ),
                if (onPdf != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: pdfEnabled ? onPdf : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: pdfEnabled
                            ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)])
                            : null,
                        color: pdfEnabled ? null : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: pdfEnabled ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.picture_as_pdf_rounded, size: 15, color: pdfEnabled ? Colors.white : const Color(0xFFCBD5E1)),
                        const SizedBox(width: 6),
                        Text('PDF Report', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: pdfEnabled ? Colors.white : const Color(0xFFCBD5E1))),
                      ]),
                    ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String tag,
    required Color tagColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF475569))),
              Text(description, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8)), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('Soon', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: tagColor, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown({required String? value, required ValueChanged<String?> onChanged, required String hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text(hint, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(hint, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600))),
            ..._classes.map((c) {
              final name = '${c['name'] ?? ''} ${c['section'] ?? ''}'.trim();
              return DropdownMenuItem<String?>(value: c['id'] as String?, child: Text(name, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)));
            }),
          ],
          onChanged: onChanged,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildExamDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _marksExamId,
          isExpanded: true,
          isDense: true,
          hint: Text('Select Exam', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text('Select Exam', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600))),
            ..._exams.map((e) => DropdownMenuItem<String?>(
              value: e['id'] as String?,
              child: Text(e['name'] ?? 'Exam', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
            )),
          ],
          onChanged: (v) => setState(() => _marksExamId = v),
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }
}
