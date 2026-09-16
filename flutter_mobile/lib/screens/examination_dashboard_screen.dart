import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/custom_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'exams_screen.dart';
import 'marks_upload_screen.dart';
import 'question_papers_screen.dart';
import 'results_screen.dart';
import 'progress_card_screen.dart';
import 'settings_screen.dart';
import 'exam_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class ExaminationDashboardScreen extends StatefulWidget {
  const ExaminationDashboardScreen({super.key});

  @override
  State<ExaminationDashboardScreen> createState() => _ExaminationDashboardScreenState();
}

class _ExaminationDashboardScreenState extends State<ExaminationDashboardScreen> {
  String _userRole = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initRole();
  }

  Future<void> _initRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final userStr = prefs.getString('user');
      if (userStr != null) {
        _userRole = jsonDecode(userStr)['role'] ?? '';
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isTeacher = _userRole == 'TEACHER';

    final List<Widget> cards = [
      if (!isTeacher) _buildDashboardCard(
        context,
        title: 'Exams List',
        subtitle: 'Manage exams',
        imageUrl: 'https://img.icons8.com/3d-fluency/94/books.png',
        color: const Color(0xFF4F46E5),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExamsScreen())),
      ),
      if (!isTeacher) _buildDashboardCard(
        context,
        title: 'Admit Card',
        subtitle: 'Hall tickets',
        imageUrl: 'https://img.icons8.com/3d-fluency/94/name-tag.png',
        color: const Color(0xFF0EA5E9),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Container())),
      ),
      _buildDashboardCard(
        context,
        title: 'Question Papers',
        subtitle: 'Upload & manage',
        imageUrl: 'https://img.icons8.com/3d-fluency/94/document.png',
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QuestionPapersScreen())),
      ),
      _buildDashboardCard(
        context,
        title: 'Marks Upload',
        subtitle: 'Enter marks',
        imageUrl: 'https://img.icons8.com/3d-fluency/94/edit.png',
        color: const Color(0xFF10B981),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MarksUploadScreen())),
      ),
      _buildDashboardCard(
        context,
        title: 'Results',
        subtitle: 'Grade sheets',
        imageUrl: 'https://img.icons8.com/3d-fluency/94/medal.png',
        color: const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultsScreen())),
      ),
      _buildDashboardCard(
        context,
        title: 'Progress Card',
        subtitle: 'Detailed progress',
        imageUrl: 'https://img.icons8.com/3d-fluency/94/combo-chart.png',
        color: const Color(0xFFF43F5E),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgressCardScreen())),
      ),
      _buildDashboardCard(
        context,
        title: 'Answer Key',
        subtitle: 'Upload keys',
        imageUrl: 'https://img.icons8.com/3d-fluency/94/key.png',
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Container())),
      ),
      if (!isTeacher) _buildDashboardCard(
        context,
        title: 'Slip Test Rank',
        subtitle: 'Manual ranks',
        imageUrl: 'https://img.icons8.com/3d-fluency/94/target.png',
        color: const Color(0xFF06B6D4),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Container())),
      ),
      if (!isTeacher) _buildDashboardCard(
        context,
        title: 'Send SMS',
        subtitle: 'Notify parents',
        imageUrl: 'https://img.icons8.com/3d-fluency/94/speech-bubble-with-dots.png',
        color: const Color(0xFFEC4899),
        onTap: () => _showSendSmsBottomSheet(context),
      ),
      _buildDashboardCard(
        context,
        title: 'Overview',
        subtitle: 'Track progress',
        imageUrl: 'https://img.icons8.com/3d-fluency/94/search.png',
        color: const Color(0xFFF97316),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Container())),
      ),
      if (!isTeacher) _buildDashboardCard(
        context,
        title: 'Settings',
        subtitle: 'Configurations',
        imageUrl: 'https://img.icons8.com/3d-fluency/94/gear.png',
        color: const Color(0xFF64748B),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExamSettingsScreen())),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light modern background
      drawer: const AppDrawer(currentRoute: 'exams'),
      appBar: AppBar(
        title: Text(
          'Examination Dashboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4C4296), Color(0xFF2E2A66)], // Signature Rajesh Tution Point Purple
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Subtle background decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4C4296).withOpacity(0.03),
              ),
            ),
          ),
          GridView.count(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9, 
            children: cards,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imageUrl,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: color.withOpacity(0.1),
      highlightColor: color.withOpacity(0.05),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: CustomNetworkImage(
                imageUrl,
                width: 26,
                height: 26,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.apps_rounded, color: color, size: 24),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }


  void _showSendSmsBottomSheet(BuildContext context) async {
    // Show a beautifully designed bottom sheet to send SMS
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const _SendSmsBottomSheet();
      },
    );
  }
}

class _SendSmsBottomSheet extends StatefulWidget {
  const _SendSmsBottomSheet();

  @override
  State<_SendSmsBottomSheet> createState() => _SendSmsBottomSheetState();
}

class _SendSmsBottomSheetState extends State<_SendSmsBottomSheet> {
  bool _isLoading = false;
  List<dynamic> _exams = [];
  List<dynamic> _classes = [];
  String? _selectedExam;
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final eRes = await ApiService.getExams();
    final cRes = await ApiService.getClasses();
    if (mounted) {
      setState(() {
        _exams = eRes['success'] ? (eRes['data'] ?? []) : [];
        _classes = cRes['success'] ? (cRes['data'] ?? []) : [];
      });
    }
  }

  Future<void> _sendSms() async {
    if (_selectedExam == null || _selectedClass == null) return;
    setState(() => _isLoading = true);
    final res = await ApiService.sendMarksSMS(_selectedExam!, _selectedClass!, {});
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['success'] ? 'SMS Sent Successfully' : res['message'] ?? 'Failed to send SMS'),
        backgroundColor: res['success'] ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Send Marks SMS', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Select Exam', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedExam,
                  hint: const Text('Select Exam'),
                  items: _exams.map((e) => DropdownMenuItem<String>(value: e['id'].toString(), child: Text(e['name'] ?? 'Unknown'))).toList(),
                  onChanged: (val) => setState(() => _selectedExam = val),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Select Class', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedClass,
                  hint: const Text('Select Class'),
                  items: _classes.map((c) => DropdownMenuItem<String>(value: c['id'].toString(), child: Text('${c['name']} - ${c['section']}'))).toList(),
                  onChanged: (val) => setState(() => _selectedClass = val),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading || _selectedExam == null || _selectedClass == null ? null : _sendSms,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('Send SMS', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




