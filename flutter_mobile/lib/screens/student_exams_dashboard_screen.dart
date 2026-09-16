import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import 'student_question_papers_screen.dart';
import 'student_results_screen.dart';
import 'student_progress_card_screen.dart';
import 'quizzes_screen.dart';

class StudentExamsDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const StudentExamsDashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Exams & Results', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E2A66), Color(0xFF222854)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                _buildModuleCard(
                  context: context,
                  title: 'Admit Card',
                  subtitle: 'Hall Tickets',
                  icon: Icons.confirmation_number_rounded,
                  colors: [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                  onTap: () => {},
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Question Papers',
                  subtitle: 'Study Material',
                  icon: Icons.assignment_rounded,
                  colors: [const Color(0xFF059669), const Color(0xFF10B981)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentQuestionPapersScreen(user: user))),
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Results',
                  subtitle: 'Notice Board',
                  icon: Icons.emoji_events_rounded,
                  colors: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentResultsScreen(user: user))),
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Progress Card',
                  subtitle: 'Report Cards',
                  icon: Icons.insert_chart_rounded,
                  colors: [const Color(0xFFDB2777), const Color(0xFFEC4899)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentProgressCardScreen(user: user))),
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Exam Schedule',
                  subtitle: 'Timetable',
                  icon: Icons.event_note_rounded,
                  colors: [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                  onTap: () {},
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Academic Calendar',
                  subtitle: 'Yearly Plan',
                  icon: Icons.calendar_month_rounded,
                  colors: [const Color(0xFF06B6D4), const Color(0xFF22D3EE)],
                  onTap: () {},
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Quiz',
                  subtitle: 'Daily Tests',
                  icon: Icons.quiz_rounded,
                  colors: [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
                  onTap: () {},
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Online Quizzes',
                  subtitle: 'Mock Tests',
                  icon: Icons.laptop_chromebook_rounded,
                  colors: [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizzesScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background subtle accent
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(icon, size: 80, color: colors.first.withOpacity(0.04)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.first.withOpacity(0.15), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: colors.first.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: colors.first, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle, 
                        style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
