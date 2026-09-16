import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import 'create_exam_screen.dart';
import 'marks_upload_screen.dart';


class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  List<dynamic> _examResults = [];
  List<dynamic> _examsList = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole;
  String? _expandedExamId;

  // Vibrant gradients for the exam cards
  final List<List<Color>> _cardGradients = [
    [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Indigo to Purple
    [const Color(0xFFEC4899), const Color(0xFFF43F5E)], // Pink to Rose
    [const Color(0xFF10B981), const Color(0xFF34D399)], // Emerald
    [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], // Amber
    [const Color(0xFF3B82F6), const Color(0xFF2DD4BF)], // Blue to Teal
  ];

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString == null) {
        setState(() {
          _errorMessage = 'User session not found';
          _isLoading = false;
        });
        return;
      }

      final user = jsonDecode(userString);
      _userRole = user['role'];

      if (_userRole == 'STUDENT') {
        final studentId = user['student']?['id'];
        if (studentId == null) {
          setState(() {
            _errorMessage = 'Student profile information not found';
            _isLoading = false;
          });
          return;
        }

        final result = await ApiService.getMarks(studentId);

        if (mounted) {
          if (result['success']) {
            setState(() {
              _examResults = result['data'] ?? [];
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = result['message'];
              _isLoading = false;
            });
          }
        }
      } else {
        // Teacher or Admin -> Fetch exams list
        final result = await ApiService.getExams();
        
        if (mounted) {
          if (result['success']) {
            setState(() {
              final data = result['data'];
              _examsList = data is List ? data : (data is Map && data['data'] is List ? data['data'] : []);
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = result['message'];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteExam(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Exam', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this exam? All associated marks will also be deleted.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade700, fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true), 
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Simulate API call for now
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam delete requested (Requires API support)')));
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A1':
      case 'A2':
      case 'A+':
      case 'A':
        return const Color(0xFF10B981); // Emerald
      case 'B1':
      case 'B2':
      case 'B+':
      case 'B':
        return const Color(0xFF3B82F6); // Blue
      case 'C1':
      case 'C2':
      case 'C+':
      case 'C':
        return const Color(0xFFF59E0B); // Amber
      case 'F':
      case 'FAIL':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isStudent = _userRole == 'STUDENT';
    final title = isStudent ? 'My Results' : 'Examinations';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Lighter, cleaner background
      drawer: const AppDrawer(currentRoute: 'exams'),
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _fetchResults,
            ),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: (!isStudent && (_userRole == 'SUPER_ADMIN' || _userRole == 'ADMIN' || _userRole == 'TEACHER')) 
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))
                ]
              ),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateExamScreen()))
                      .then((value) { if (value == true) _fetchResults(); });
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                highlightElevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                label: Text('New Exam', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            )
          : null,
      body: Stack(
        children: [
          // Background subtle decorations
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF6366F1).withOpacity(0.05)),
            ),
          ),
          Positioned(
            bottom: -50, left: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEC4899).withOpacity(0.05)),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 70, color: Color(0xFFEF4444)),
                            const SizedBox(height: 16),
                            Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF475569))),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _fetchResults, 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)
                              ),
                              child: Text('Retry', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white))
                            )
                          ],
                        ),
                      )
                    : isStudent
                        ? _buildStudentResults()
                        : _buildExamsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsList() {
    if (_examsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
              child: const Icon(Icons.layers_rounded, size: 80, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 24),
            Text("No Examinations Found", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
            const SizedBox(height: 8),
            Text("Click 'New Exam' to schedule one.", style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchResults,
      color: const Color(0xFF6366F1),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 100),
        itemCount: _examsList.length,
        itemBuilder: (context, index) {
          final exam = _examsList[index];
          if (exam == null || exam is! Map) return const SizedBox();
          
          final String id = exam['id']?.toString() ?? index.toString();
          final String name = exam['name']?.toString() ?? 'Unknown Exam';
          final String term = exam['term']?.toString() ?? '';
          
          final String dateStr = exam['examDate']?.toString() ?? '';
          String formattedDate = 'No Date';
          if (dateStr.isNotEmpty) {
            try {
              final DateTime d = DateTime.parse(dateStr);
              formattedDate = "${d.day}/${d.month}/${d.year}"; // Simple format
            } catch (_) {}
          }

          final List<dynamic> classes = exam['classes'] as List? ?? [];
          final bool isExpanded = _expandedExamId == id;
          final gradient = _cardGradients[index % _cardGradients.length];

          return GestureDetector(
            onTap: () {
              setState(() {
                _expandedExamId = isExpanded ? null : id;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(isExpanded ? 0.15 : 0.05),
                    blurRadius: isExpanded ? 20 : 10,
                    offset: Offset(0, isExpanded ? 8 : 4),
                  )
                ],
                border: Border.all(color: gradient[0].withOpacity(0.4), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (term.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                            child: Text(term, style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Icon(Icons.calendar_today_rounded, size: 12, color: const Color(0xFF94A3B8)),
                                        const SizedBox(width: 4),
                                        Text(formattedDate, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: classes.take(isExpanded ? classes.length : 4).map<Widget>((c) {
                              final className = c['name'] ?? c['className'] ?? '';
                              final section = c['section'] ?? '';
                              final display = section.isEmpty ? className : '$className-$section';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: gradient[0].withOpacity(0.05),
                                  border: Border.all(color: gradient[0].withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(display, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: gradient[0])),
                              );
                            }).toList()..addAll(!isExpanded && classes.length > 4 ? [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('+${classes.length - 4}', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                              )
                            ] : []),
                          ),
                          
                          // Expandable Actions
                          AnimatedCrossFade(
                            firstChild: const SizedBox(height: 0, width: double.infinity),
                            secondChild: Column(
                              children: [
                                const SizedBox(height: 16),
                                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (_userRole == 'SUPER_ADMIN')
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _deleteExam(id),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFEF4444),
                                            side: const BorderSide(color: Color(0xFFFECACA)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                          label: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ),
                                    if (_userRole == 'SUPER_ADMIN') const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => MarksUploadScreen(initialExamId: id)));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: gradient[0],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                                        label: Text('Enter Grades', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // OMR Scanner removed
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981), // Emerald green
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                        icon: const Icon(Icons.document_scanner_rounded, size: 16),
                                        label: Text('Scan OMR Sheet', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentResults() {
    if (_examResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
              child: const Icon(Icons.assignment_turned_in_rounded, size: 80, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 24),
            Text("No Results Found", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
            const SizedBox(height: 8),
            Text("You don't have any exam marks yet.", style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14)),
          ],
        ),
      );
    }
    
    // The backend returns a list of { exam: {}, marks: [] } objects
    return RefreshIndicator(
      onRefresh: _fetchResults,
      color: const Color(0xFF6366F1),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 40),
        itemCount: _examResults.length,
        itemBuilder: (context, index) {
          final examResult = _examResults[index];
          final examName = examResult['exam']?['name'] ?? 'Unknown Exam';
          final marks = (examResult['marks'] as List?) ?? [];
          
          double totalObtained = 0;
          double totalMax = 0;
          
          for (var m in marks) {
            totalObtained += double.tryParse(m['marksObtained']?.toString() ?? '0') ?? 0;
            totalMax += double.tryParse(m['maxMarks']?.toString() ?? '100') ?? 100;
          }
          if (totalMax == 0) totalMax = 1;
          double percentage = (totalObtained / totalMax);

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF4F46E5)], // Indigo Dark to Indigo
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Scorecard
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: percentage,
                              strokeWidth: 6,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(percentage >= 0.35 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                            ),
                            Center(
                              child: Text(
                                '${(percentage * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              examName,
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Total: ${totalObtained.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Subjects List
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: marks.map<Widget>((m) {
                      final subjectName = m['subject']?['name'] ?? 'Unknown';
                      final obtained = m['marksObtained']?.toString() ?? '-';
                      final max = m['maxMarks']?.toString() ?? '-';
                      final grade = m['grade'] ?? '-';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(subjectName, style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text('Max Marks: $max', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(obtained, style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontSize: 22, fontWeight: FontWeight.w800)),
                                    Text('Score', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(grade).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _getGradeColor(grade).withOpacity(0.3), width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      grade,
                                      style: GoogleFonts.outfit(color: _getGradeColor(grade), fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ExamResultCard extends StatefulWidget {
  final String examName;
  final double percentage;
  final double totalObtained;
  final double totalMax;
  final List<dynamic> marks;
  const ExamResultCard({Key? key, required this.examName, required this.percentage, required this.totalObtained, required this.totalMax, required this.marks}) : super(key: key);
  @override
  _ExamResultCardState createState() => _ExamResultCardState();
}

class _ExamResultCardState extends State<ExamResultCard> {
  bool _isExpanded = false;
  
  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+': case 'A': return const Color(0xFF10B981);
      case 'B+': case 'B': return const Color(0xFF3B82F6);
      case 'C': return const Color(0xFFF59E0B);
      case 'D': return const Color(0xFFEF4444);
      case 'F': default: return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: _isExpanded 
              ? const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))
              : BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: _isExpanded 
                  ? const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))
                  : BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: widget.percentage,
                          strokeWidth: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(widget.percentage >= 0.35 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                        ),
                        Center(
                          child: Text(
                            '${(widget.percentage * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
                          ),
                        )
                      ],
                    ),
                  ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.examName,
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Total: ${widget.totalObtained.toStringAsFixed(0)} / ${widget.totalMax.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: widget.marks.map<Widget>((m) {
                      final subjectName = m['subject']?['name'] ?? 'Unknown';
                      final obtained = m['marksObtained']?.toString() ?? '-';
                      final max = m['maxMarks']?.toString() ?? '-';
                      final grade = m['grade'] ?? '-';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(subjectName, style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text('Max Marks: $max', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(obtained, style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontSize: 22, fontWeight: FontWeight.w800)),
                                    Text('Score', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(grade).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _getGradeColor(grade).withOpacity(0.3), width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      grade,
                                      style: GoogleFonts.outfit(color: _getGradeColor(grade), fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      }
    }
