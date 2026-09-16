import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'single_progress_card_screen.dart';

class StudentProgressCardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const StudentProgressCardScreen({super.key, required this.user});

  @override
  State<StudentProgressCardScreen> createState() => _StudentProgressCardScreenState();
}

class _StudentProgressCardScreenState extends State<StudentProgressCardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _exams = [];

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final classId = widget.user['student']?['classId']?.toString();
      if (classId == null) throw 'Class information not found.';
      
      final res = await ApiService.getExams(classId: classId);
      if (res['success']) {
        setState(() {
          _exams = res['data'] ?? [];
        });
      } else {
        throw res['message'] ?? 'Failed to load exams';
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openProgressCard(Map<String, dynamic> exam) {
    final classId = widget.user['student']?['classId']?.toString();
    final studentId = widget.user['student']?['id']?.toString();
    
    if (classId == null || studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing student information')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SingleProgressCardScreen(
          examId: exam['id'].toString(),
          classId: classId,
          studentId: studentId,
          examName: exam['name'] ?? 'Exam',
          className: widget.user['student']?['class']?['name'] ?? 'Class',
          studentData: widget.user['student'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text('My Progress Cards', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
              : _exams.isEmpty
                  ? Center(child: Text('No active exams found for your class.', style: GoogleFonts.poppins(color: Colors.grey[600])))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _exams.length,
                      itemBuilder: (context, index) {
                        final exam = _exams[index];
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
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.insert_chart_rounded, color: Color(0xFF4F46E5), size: 28),
                            ),
                            title: Text(exam['name'] ?? 'Exam', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1E293B))),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Click to view and download your progress report for this exam.', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                            onTap: () => _openProgressCard(exam),
                          ),
                          ),
                        );
                      },
                    ),
    );
  }
}
