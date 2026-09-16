import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class StudentQuestionPapersScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const StudentQuestionPapersScreen({super.key, required this.user});

  @override
  State<StudentQuestionPapersScreen> createState() => _StudentQuestionPapersScreenState();
}

class _StudentQuestionPapersScreenState extends State<StudentQuestionPapersScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _papers = [];

  @override
  void initState() {
    super.initState();
    _fetchPapers();
  }

  Future<void> _fetchPapers() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final studentClassId = widget.user['student']?['classId']?.toString();
      if (studentClassId == null) throw 'Class information not found.';

      final res = await ApiService.getQuestionPapers();
      if (res['success']) {
        final allPapers = res['data'] as List<dynamic>? ?? [];
        setState(() {
          _papers = allPapers.where((paper) {
            final classId = paper['classId']?.toString();
            final status = paper['status']?.toString();
            // Only show PUBLISHED papers for the student's class
            return classId == studentClassId && status == 'PUBLISHED';
          }).toList();
        });
      } else {
        throw res['message'] ?? 'Failed to load question papers';
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    String finalUrl = url.trim();
    if (!finalUrl.startsWith('http')) {
      finalUrl = finalUrl.startsWith('/') ? '${ApiService.baseUrl}$finalUrl' : '${ApiService.baseUrl}/$finalUrl';
    }

    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open the file link: $finalUrl')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text('My Question Papers', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _papers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_late_rounded, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No question papers available yet.', style: GoogleFonts.poppins(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPapers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _papers.length,
                        itemBuilder: (context, index) {
                          final p = _papers[index];
                          final title = p['title'] ?? 'Question Paper';
                          final examName = p['exam']?['name'] ?? 'Exam';
                          final term = p['exam']?['term'] ?? '';
                          final subjectName = p['subject']?['name'] ?? 'Subject';
                          final maxMarks = p['maxMarks'] ?? '-';
                          final duration = p['durationMinutes'] ?? '-';
                          final date = p['createdAt'] != null ? p['createdAt'].toString().substring(0, 10) : '';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                              border: Border.all(color: Colors.grey[100]!),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
                                        child: Text(subjectName, style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                      const Spacer(),
                                      Text(date, style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                  const SizedBox(height: 4),
                                  Text('$examName ${term.isNotEmpty ? '($term)' : ''}', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
                                  
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text('$duration mins', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                                      const SizedBox(width: 16),
                                      Icon(Icons.grade_outlined, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text('$maxMarks Marks', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  const SizedBox(height: 16),
                                  
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        if (p['fileUrl'] != null && p['fileUrl'].toString().isNotEmpty) {
                                          _launchUrl(p['fileUrl']);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF not available for this paper')));
                                        }
                                      },
                                      icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                                      label: Text('Download Question Paper', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF059669),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
