import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'profile_screen.dart';
import 'students_screen.dart';
import 'teachers_screen.dart';
import 'classes_screen.dart';
import 'finance_screen.dart';
import 'student_fee_search_screen.dart';
import 'student_exams_dashboard_screen.dart';
import 'student_finance_dashboard_screen.dart';
import 'student_profile_screen.dart';
import 'homework_screen.dart';
import 'messages_screen.dart';
import 'announcements_screen.dart';
import 'attendance_screen.dart';
import 'study_materials_screen.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  String _userRole = '';
  Map<String, dynamic> _userMap = {};
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
        _userMap = jsonDecode(userStr);
        _userRole = _userMap['role'] ?? '';
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
    final isStudent = _userRole == 'STUDENT';

    final List<Map<String, dynamic>> adminModules = [
      {'title': 'Students', 'icon': Icons.people_rounded, 'color': const Color(0xFF6366F1), 'page': const StudentsScreen()},
      {'title': 'Teachers', 'icon': Icons.school_rounded, 'color': const Color(0xFF10B981), 'page': const TeachersScreen()},
      {'title': 'Classes', 'icon': Icons.domain_rounded, 'color': const Color(0xFF3B82F6), 'page': ClassesScreen()},
      {'title': 'Finance', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFFF43F5E), 'page': const FinanceScreen()},
      {'title': 'Fee Collection', 'icon': Icons.credit_card_rounded, 'color': const Color(0xFF8B5CF6), 'page': const StudentFeeSearchScreen()},
      {'title': 'Attendance', 'icon': Icons.how_to_reg_rounded, 'color': const Color(0xFFD97706), 'page': const AttendanceScreen()},
      {'title': 'Announcements', 'icon': Icons.campaign_rounded, 'color': const Color(0xFF0EA5E9), 'page': const AnnouncementsScreen()},
      {'title': 'Messages', 'icon': Icons.chat_rounded, 'color': const Color(0xFF14B8A6), 'page': const MessagesScreen()},
      {'title': 'Reports', 'icon': Icons.bar_chart_rounded, 'color': const Color(0xFFEC4899), 'page': const ReportsScreen()},
      {'title': 'Settings', 'icon': Icons.settings_rounded, 'color': const Color(0xFF475569), 'page': const SettingsScreen()},
    ];

    final List<Map<String, dynamic>> teacherModules = [
      {'title': 'My Students', 'icon': Icons.people_rounded, 'color': const Color(0xFF6366F1), 'page': const StudentsScreen()},
      {'title': 'Attendance', 'icon': Icons.how_to_reg_rounded, 'color': const Color(0xFFD97706), 'page': const AttendanceScreen()},
      {'title': 'Homework', 'icon': Icons.assignment_rounded, 'color': const Color(0xFFEA580C), 'page': const HomeworkScreen()},
      {'title': 'Study Material', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF059669), 'page': const StudyMaterialsScreen()},
      {'title': 'Announcements', 'icon': Icons.campaign_rounded, 'color': const Color(0xFF0EA5E9), 'page': const AnnouncementsScreen()},
      {'title': 'Messages', 'icon': Icons.chat_rounded, 'color': const Color(0xFF14B8A6), 'page': const MessagesScreen()},
      {'title': 'Profile', 'icon': Icons.person_rounded, 'color': const Color(0xFF8B5CF6), 'page': const ProfileScreen()},
      {'title': 'Settings', 'icon': Icons.settings_rounded, 'color': const Color(0xFF475569), 'page': const SettingsScreen()},
    ];

    final List<Map<String, dynamic>> studentModules = [
      {'title': 'My Fees', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF16A34A), 'page': StudentFinanceDashboardScreen(user: _userMap)},
      {'title': 'Homework', 'icon': Icons.assignment_rounded, 'color': const Color(0xFFEA580C), 'page': const HomeworkScreen()},
      {'title': 'Announcements', 'icon': Icons.campaign_rounded, 'color': const Color(0xFF6D28D9), 'page': const AnnouncementsScreen()},
      {'title': 'Study Material', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF0284C7), 'page': const StudyMaterialsScreen()},
      {'title': 'Exam Schedule', 'icon': Icons.event_note_rounded, 'color': const Color(0xFF0284C7), 'page': StudentExamsDashboardScreen(user: _userMap)},
      {'title': 'Message Teacher', 'icon': Icons.chat_rounded, 'color': const Color(0xFF14B8A6), 'page': const MessagesScreen()},
      {'title': 'Profile', 'icon': Icons.person_rounded, 'color': const Color(0xFF8B5CF6), 'page': StudentProfileScreen(student: _userMap['student'] ?? {})},
      {'title': 'Quiz', 'icon': Icons.quiz_rounded, 'color': const Color(0xFF0EA5E9), 'page': null},
      {'title': 'Feedback', 'icon': Icons.feedback_rounded, 'color': const Color(0xFF84CC16), 'page': null},
    ];

    final modules = isStudent ? studentModules : (isTeacher ? teacherModules : adminModules);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: Text(
          'More',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00114F), Color(0xFF000A30)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.85,
        ),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          return _buildModuleCard(
            context,
            module['title'],
            module['icon'],
            module['color'],
            module['page'],
          );
        },
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, IconData icon, Color color, Widget? page) {
    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon...')),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF1E293B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
