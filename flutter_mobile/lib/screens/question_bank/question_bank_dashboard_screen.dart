import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/app_drawer.dart';
import 'question_paper_generator_screen.dart';
import 'exam_paper_generator_screen.dart';
import 'saved_papers_screen.dart';

class QuestionBankDashboardScreen extends StatelessWidget {
  const QuestionBankDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      {
        'title': 'AI Paper Generator',
        'description': 'Dual-layout paper creator',
        'icon': Icons.file_upload_outlined,
        'color1': const Color(0xFF1D4ED8), // from-blue-700
        'color2': const Color(0xFF6366F1), // to-indigo-500
        'route': '/question-bank/generator',
      },
      {
        'title': 'Saved AI Papers',
        'description': 'View and edit saved papers',
        'icon': Icons.description_outlined,
        'color1': const Color(0xFF0284C7), // from-sky-600
        'color2': const Color(0xFF06B6D4), // to-cyan-500
        'route': '/question-bank/saved',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_rounded, color: Color(0xFF6366F1), size: 24),
            const SizedBox(width: 12),
            Text(
              'Question Bank Hub',
              style: GoogleFonts.outfit(
                color: const Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: 'question_bank'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth > 900) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth > 600) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth > 400) {
            crossAxisCount = 2;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: tools.length,
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    return _buildDashboardCard(context, tool);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, Map<String, dynamic> tool) {
    return Card(
      elevation: 4,
      shadowColor: (tool['color2'] as Color).withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.indigo.shade50, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Widget? nextScreen;
          switch (tool['route']) {
            case '/question-bank/generator':
              nextScreen = const QuestionPaperGeneratorScreen();
              break;
            case '/question-bank/saved':
              nextScreen = const SavedPapersScreen();
              break;
            case '/question-bank/navodaya':
            case '/question-bank/mcq':
            case '/question-bank/answer-key':
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon...'), behavior: SnackBarBehavior.floating),
              );
              return;
          }
          if (nextScreen != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => nextScreen!),
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Stack(
            children: [
              // Hover glow effect approximation
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        (tool['color1'] as Color).withOpacity(0.05),
                        (tool['color2'] as Color).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [tool['color1'] as Color, tool['color2'] as Color],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (tool['color1'] as Color).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            tool['icon'] as IconData,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool['title'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tool['description'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4338CA),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
