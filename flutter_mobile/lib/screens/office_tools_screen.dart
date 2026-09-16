import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_drawer.dart';


class OfficeToolsScreen extends StatelessWidget {
  const OfficeToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _ToolItem(
        title: 'STUDY CERTIFICATE',
        description: 'Generate study certificates for students',
        icon: Icons.school_rounded,
        colors: [const Color(0xFF0EA5E9), const Color(0xFF06B6D4)],
        onTap: () => _comingSoon(context),
      ),
      _ToolItem(
        title: 'SLIP TEST RANK CARD',
        description: 'Generate slip test rank cards and reports',
        icon: Icons.military_tech_rounded,
        colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        onTap: () => _comingSoon(context),
      ),
      _ToolItem(
        title: 'DUPLICATE PROGRESS CARD',
        description: 'Issue duplicate academic progress cards',
        icon: Icons.content_copy_rounded,
        colors: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
        onTap: () => _comingSoon(context),
      ),
      _ToolItem(
        title: 'ORIGINAL PROGRESS CARD',
        description: 'Generate original academic progress cards',
        icon: Icons.insert_drive_file_rounded,
        colors: [const Color(0xFFEC4899), const Color(0xFFF43F5E)],
        onTap: () => _comingSoon(context),
      ),
      _ToolItem(
        title: 'TRANSFER CERTIFICATE',
        description: 'Issue transfer certificates (TC)',
        icon: Icons.transfer_within_a_station_rounded,
        colors: [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
        onTap: () => _comingSoon(context),
      ),
      _ToolItem(
        title: 'CHARACTER CERTIFICATE',
        description: 'Issue character certificates for students',
        icon: Icons.verified_rounded,
        colors: [const Color(0xFF10B981), const Color(0xFF059669)],
        onTap: () => _comingSoon(context),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      drawer: const AppDrawer(currentRoute: 'office_tools'),
      appBar: AppBar(
        title: Text('Office Tools', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Office Tools', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Generate certificates & documents', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text('${tools.length} Tools', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Grid of tools
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: tools.map((tool) => _buildToolCard(context, tool)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, _ToolItem tool) {
    return GestureDetector(
      onTap: tool.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: tool.colors),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: tool.colors),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: tool.colors[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Icon(tool.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tool.title,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B)),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tool.description,
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      maxLines: 2,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: tool.colors[0].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.arrow_forward_rounded, size: 14, color: tool.colors[0]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.construction_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text('This feature is coming soon!', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: const Color(0xFF6366F1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

class _ToolItem {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  const _ToolItem({required this.title, required this.description, required this.icon, required this.colors, required this.onTap});
}
