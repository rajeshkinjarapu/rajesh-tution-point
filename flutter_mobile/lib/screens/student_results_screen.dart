import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'single_progress_card_screen.dart';

class StudentResultsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const StudentResultsScreen({super.key, required this.user});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  bool _isLoadingExams = true;
  bool _isLoadingResults = false;
  String? _errorMessage;
  
  List<dynamic> _exams = [];
  Map<String, dynamic>? _selectedExam;
  List<dynamic> _results = [];

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() { _isLoadingExams = true; _errorMessage = null; });
    try {
      final classId = widget.user['student']?['classId']?.toString();
      if (classId == null) throw 'Class information not found.';

      final res = await ApiService.getExams(classId: classId);
      if (res['success']) {
        setState(() {
          _exams = res['data'] ?? [];
          if (_exams.isNotEmpty) {
            _selectedExam = _exams.first;
            _fetchResults();
          }
        });
      } else {
        throw res['message'] ?? 'Failed to load exams';
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingExams = false);
    }
  }

  Future<void> _fetchResults() async {
    if (_selectedExam == null) return;
    setState(() { _isLoadingResults = true; _errorMessage = null; _results = []; });
    try {
      final classId = widget.user['student']?['classId']?.toString();
      if (classId == null) throw 'Class information not found.';

      final res = await ApiService.getExamResults(_selectedExam!['id'].toString(), classId: classId);
      if (res['success']) {
        List<dynamic> allRes = res['data'] ?? [];
        
        // Sort by total marks descending (Rank calculation)
        allRes.sort((a, b) {
          final tA = double.tryParse(a['total']?.toString() ?? a['totalMarks']?.toString() ?? '0') ?? 0.0;
          final tB = double.tryParse(b['total']?.toString() ?? b['totalMarks']?.toString() ?? '0') ?? 0.0;
          return tB.compareTo(tA); // Descending
        });

        setState(() {
          _results = allRes;
        });
      } else {
        throw res['message'] ?? 'Failed to load results';
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingResults = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text('Notice Board (Results)', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
      body: _isLoadingExams
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _exams.isEmpty
                  ? Center(child: Text('No active exams found for your class.', style: GoogleFonts.poppins(color: Colors.grey[600])))
                  : Column(
                      children: [
                        // Exam Selector
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedExam?['id']?.toString(),
                              items: _exams.map((e) => DropdownMenuItem<String>(
                                value: e['id']?.toString(),
                                child: Text(e['name']?.toString() ?? 'Exam', style: GoogleFonts.poppins()),
                              )).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedExam = _exams.firstWhere((e) => e['id']?.toString() == val, orElse: () => _exams.first);
                                  _fetchResults();
                                });
                              },
                            ),
                          ),
                        ),
                        
                        Expanded(
                          child: _isLoadingResults
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                              : _results.isEmpty
                                  ? Center(child: Text('No results published yet.', style: GoogleFonts.poppins(color: Colors.grey[600])))
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: _results.length,
                                      itemBuilder: (context, index) {
                                        final r = _results[index];
                                        final sName = r['name']?.toString() ?? r['student']?['user']?['name'] ?? r['student']?['firstName'] ?? 'Student';
                                        final sRoll = r['rollNo']?.toString() ?? r['student']?['rollNo'] ?? '-';
                                        final total = r['total']?.toString() ?? r['totalMarks']?.toString() ?? '0';
                                        
                                        // Calculate total max marks if maxMarks is not provided but subjects exist
                                        double calculatedMax = 0;
                                        if (r['marks'] != null && r['marks'] is List) {
                                          for (var m in r['marks']) {
                                            calculatedMax += (m['max'] as num?)?.toDouble() ?? (m['maxMarks'] as num?)?.toDouble() ?? 100.0;
                                          }
                                        }
                                        final max = r['maxMarks']?.toString() ?? (calculatedMax > 0 ? calculatedMax.toStringAsFixed(0) : '-');
                                        
                                        final perc = r['percentage']?.toString() ?? '0';
                                        final grade = r['grade'] ?? '-';
                                        
                                        final isMe = widget.user['student']?['id']?.toString() == r['studentId']?.toString() || widget.user['student']?['id']?.toString() == r['student']?['id']?.toString();

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color: isMe ? const Color(0xFFEEF2FF) : Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
                                            ],
                                            border: Border.all(color: isMe ? const Color(0xFF6366F1) : Colors.grey[200]!, width: isMe ? 2 : 1),
                                          ),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.all(12),
                                            onTap: () {
                                              Navigator.push(context, MaterialPageRoute(builder: (_) => SingleProgressCardScreen(
                                                examId: _selectedExam!['id'].toString(),
                                                classId: widget.user['student']?['classId']?.toString() ?? '',
                                                studentId: r['studentId']?.toString() ?? r['student']?['id']?.toString() ?? '',
                                                examName: _selectedExam!['name']?.toString() ?? 'Exam',
                                                className: widget.user['student']?['class']?['name']?.toString() ?? 'Class',
                                                studentData: r,
                                              )));
                                            },
                                            leading: CircleAvatar(
                                              backgroundColor: index == 0 ? Colors.amber.withOpacity(0.2) 
                                                  : index == 1 ? Colors.grey.withOpacity(0.2)
                                                  : index == 2 ? Colors.brown.withOpacity(0.2)
                                                  : const Color(0xFFF1F5F9),
                                              radius: 24,
                                              child: index < 3 
                                                ? Icon(Icons.emoji_events, color: index == 0 ? Colors.amber : index == 1 ? Colors.grey[600] : Colors.brown, size: 28)
                                                : Text('#${index + 1}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                                            ),
                                            title: Text(
                                              sName, 
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: isMe ? const Color(0xFF4F46E5) : const Color(0xFF1E293B)),
                                            ),
                                            subtitle: Text('Roll No: $sRoll  •  $perc%', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                            trailing: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text('Rank #${index + 1}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                                                Text('$total / $max', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF059669))),
                                              ],
                                            ),
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
