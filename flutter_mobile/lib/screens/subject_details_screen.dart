import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assign_subject_teacher_screen.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final String subjectName;
  final List<dynamic> subjectInstances;
  final List<dynamic> allTeachers;

  const SubjectDetailsScreen({
    super.key,
    required this.subjectName,
    required this.subjectInstances,
    required this.allTeachers,
  });

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  late List<dynamic> _instances;

  @override
  void initState() {
    super.initState();
    _instances = List.from(widget.subjectInstances);
  }

  void _onAssignTeacher(dynamic instance) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Container(),
      ),
    );

    if (result == true) {
      // Typically we'd fetch data again from API, but for simplicity here we can just pop back
      // or the user can refresh the main screen. 
      // A better way is to pop true to signal a refresh is needed.
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: Text('Subject Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFD946EF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Sleek Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 32)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subjectName,
                        style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_instances.length} Classes Enrolled',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF6366F1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // List of Classes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _instances.length,
              itemBuilder: (context, index) {
                final instance = _instances[index];
                final classObj = instance['class'] ?? {};
                final className = '${classObj['name'] ?? ''} ${classObj['section'] ?? ''}'.trim();
                
                final classSubjectTeachers = instance['classSubjectTeachers'] as List<dynamic>? ?? [];
                final teacher = classSubjectTeachers.isNotEmpty ? classSubjectTeachers.first['teacher'] : null;
                final teacherName = teacher != null ? (teacher['user']?['name'] ?? 'Unknown Teacher') : 'Unassigned';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Text(
                            className.isNotEmpty ? className.substring(0, 1) : 'G',
                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(className.isEmpty ? 'Global Subject' : className, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  teacher != null ? Icons.verified_user_rounded : Icons.person_off_rounded, 
                                  size: 14, 
                                  color: teacher != null ? const Color(0xFF10B981) : const Color(0xFFF43F5E)
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    teacherName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13, 
                                      color: teacher != null ? const Color(0xFF10B981) : const Color(0xFFF43F5E), 
                                      fontWeight: FontWeight.w600
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (teacher == null)
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: ElevatedButton(
                            onPressed: () => _onAssignTeacher(instance),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: Text('Assign', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
