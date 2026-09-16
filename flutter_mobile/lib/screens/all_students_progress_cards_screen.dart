import 'package:flutter/material.dart';
import '../widgets/custom_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'single_progress_card_screen.dart';

class AllStudentsProgressCardsScreen extends StatefulWidget {
  final String examId;
  final String classId;
  final String examName;
  final String className;
  final List<dynamic> students;

  const AllStudentsProgressCardsScreen({
    super.key,
    required this.examId,
    required this.classId,
    required this.examName,
    required this.className,
    required this.students,
  });

  @override
  State<AllStudentsProgressCardsScreen> createState() => _AllStudentsProgressCardsScreenState();
}

class _AllStudentsProgressCardsScreenState extends State<AllStudentsProgressCardsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All Progress Cards', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${widget.examName} - ${widget.className}', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF2E2A66), Color(0xFF222854)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        elevation: 0,
      ),
      body: widget.students.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: const Color(0xFFCBD5E1).withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No students found in this class.', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 15)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                final user = student['user'] ?? {};
                String name = user['name']?.toString() ?? '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'.trim();
                if (name.isEmpty) name = 'Unknown Student';
                final rollNo = student['rollNo']?.toString() ?? '-';
                final photoUrl = user['photoUrl'];
                final initials = name != 'Unknown Student' ? name.substring(0, 1).toUpperCase() : '?';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SingleProgressCardScreen(
                          examId: widget.examId,
                          classId: widget.classId,
                          studentId: student['id'].toString(),
                          studentData: student,
                          examName: widget.examName,
                          className: widget.className,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFF2E2A66).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 50, height: 50,
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)])),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: (photoUrl != null && photoUrl.toString().isNotEmpty)
                            ? CustomNetworkImage(ApiService.getImageUrl(photoUrl.toString()), fit: BoxFit.cover, errorBuilder: (c, e, s) => Center(child: Text(initials, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))))
                            : Center(child: Text(initials, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('Roll No: $rollNo', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Share Card Button
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SingleProgressCardScreen(
                                  examId: widget.examId,
                                  classId: widget.classId,
                                  studentId: student['id'].toString(),
                                  studentData: student,
                                  examName: widget.examName,
                                  className: widget.className,
                                  autoShare: true,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 14, color: Colors.white),
                          label: Text('Share Card', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            ),
    );
  }
}

