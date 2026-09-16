import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'all_students_progress_cards_screen.dart';
import 'single_progress_card_screen.dart';

class ProgressCardScreen extends StatefulWidget {
  const ProgressCardScreen({super.key});

  @override
  State<ProgressCardScreen> createState() => _ProgressCardScreenState();
}

class _ProgressCardScreenState extends State<ProgressCardScreen> {
  bool _isLoadingDropdowns = true;
  bool _isLoadingStudents = false;
  String? _errorMessage;

  List<dynamic> _examsList = [];
  List<dynamic> _classesList = [];
  List<dynamic> _students = [];

  String? _selectedExamId;
  String? _selectedClassId;
  String? _selectedStudentId;
  Map<String, dynamic>? _selectedExamData;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    setState(() => _isLoadingDropdowns = true);
    try {
      final examsRes = await ApiService.getExams();
      final classesRes = await ApiService.getClasses();

      if (mounted) {
        setState(() {
          _examsList = examsRes['success'] ? examsRes['data'] ?? [] : [];
          _classesList = classesRes['success'] ? classesRes['data'] ?? [] : [];
          _isLoadingDropdowns = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load options: $e';
          _isLoadingDropdowns = false;
        });
      }
    }
  }
  
  void _onExamSelected(String? examId) {
    if (examId == null) return;
    
    if (!_examsList.any((e) => e['id']?.toString() == examId)) {
      _selectedExamId = null;
      _selectedExamData = null;
      return;
    }

    _selectedExamId = examId;
    _selectedExamData = _examsList.firstWhere((e) => e['id']?.toString() == examId);
    
    if (_selectedClassId != null) {
      final examClasses = _selectedExamData!['classes'] as List?;
      if (examClasses == null || !examClasses.any((c) => c['id'].toString() == _selectedClassId)) {
        _selectedClassId = null;
        _students = [];
        _selectedStudentId = null;
      }
    }
  }

  Future<void> _fetchStudentsForClass() async {
    if (_selectedClassId == null) return;
    setState(() => _isLoadingStudents = true);

    try {
      final res = await ApiService.getStudents(classId: _selectedClassId);
      if (res['success']) {
        if (mounted) {
          setState(() {
            _students = res['data'] ?? [];
            _selectedStudentId = 'ALL';
            _isLoadingStudents = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingStudents = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  void _onGenerateCards() {
    if (_selectedExamId == null || _selectedClassId == null || _selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Exam, Class and Student'), backgroundColor: Colors.red));
      return;
    }

    final examData = _examsList.firstWhere((e) => e['id'].toString() == _selectedExamId, orElse: () => null);
    final className = _classesList.firstWhere((c) => c['id'].toString() == _selectedClassId, orElse: () => null)?['className']?.toString() ?? 'Class';

    if (_selectedStudentId == 'ALL') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AllStudentsProgressCardsScreen(
            examId: _selectedExamId!,
            classId: _selectedClassId!,
            examName: examData != null ? examData['name']?.toString() ?? 'Exam' : 'Exam',
            className: className,
            students: _students,
          ),
        ),
      );
    } else {
      final studentData = _students.firstWhere((s) => s['id'].toString() == _selectedStudentId, orElse: () => null);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SingleProgressCardScreen(
            examId: _selectedExamId!,
            classId: _selectedClassId!,
            studentId: _selectedStudentId!,
            studentData: studentData,
            examName: examData != null ? examData['name']?.toString() ?? 'Exam' : 'Exam',
            className: className,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Progress Cards', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
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
        elevation: 0,
      ),
      body: _isLoadingDropdowns 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E2A66))) 
          : SingleChildScrollView(
              child: SafeArea(
                bottom: true,
                child: Column(
                  children: [
                    _buildFiltersPanel(),
                    
                    if (_selectedExamId != null && _selectedClassId != null && _selectedStudentId != null)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 12),
                            Text('Ready to Generate', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                            const SizedBox(height: 8),
                            Text('Click below to view the progress cards', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B))),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _onGenerateCards,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4,
                                  shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text('Generate Progress Cards', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFiltersPanel() {
    List<dynamic> filteredClasses = [];
    
    if (_selectedExamData != null) {
      if (_selectedExamData!['classes'] != null) {
        final examClassIds = (_selectedExamData!['classes'] as List).map((c) => c['id'].toString()).toSet();
        filteredClasses = _classesList.where((c) => examClassIds.contains(c['id'].toString())).toList();
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2E2A66).withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF2E2A66).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.filter_alt_rounded, color: Color(0xFF2E2A66), size: 20),
                ),
                const SizedBox(width: 12),
                Text('Filter Options', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 24),
            _buildDropdown(
              label: 'Select Exam',
              value: _selectedExamId,
              items: _examsList,
              icon: Icons.assignment_outlined,
              onChanged: (val) {
                setState(() { _onExamSelected(val); });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: _selectedExamId == null ? 'Select Exam First' : 'Select Class',
              value: _selectedClassId,
              items: filteredClasses,
              icon: Icons.class_outlined,
              onChanged: _selectedExamId == null ? null : (val) {
                setState(() {
                  _selectedClassId = val as String?;
                  _fetchStudentsForClass();
                });
              },
            ),
            const SizedBox(height: 16),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Student', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedClassId == null ? const Color(0xFFF1F5F9) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _selectedStudentId != null ? const Color(0xFF6366F1).withOpacity(0.5) : const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedStudentId,
                      hint: _isLoadingStudents 
                          ? Row(children: [const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 12), Text('Loading...', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)))])
                          : Text(_selectedClassId == null ? 'Select Class First' : 'Select Student', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8))),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                      onChanged: _selectedClassId == null || _isLoadingStudents ? null : (val) => setState(() => _selectedStudentId = val),
                      items: _selectedClassId == null ? [] : [
                        DropdownMenuItem<String>(
                          value: 'ALL',
                          child: Row(
                            children: [
                              const Icon(Icons.people_alt_outlined, size: 20, color: Color(0xFF64748B)),
                              const SizedBox(width: 12),
                              Text('All Students', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                            ],
                          ),
                        ),
                        ..._students.map((student) {
                          final user = student['user'] ?? {};
                          String name = user['name']?.toString() ?? '${student['firstName']} ${student['lastName']}';
                          return DropdownMenuItem<String>(
                            value: student['id'].toString(),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 20, color: Color(0xFF64748B)),
                                const SizedBox(width: 12),
                                Expanded(child: Text('$name (Roll: ${student['rollNo'] ?? 'N/A'})', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<dynamic> items, required IconData icon, required Function(dynamic)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: onChanged == null ? const Color(0xFFF1F5F9) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: value != null ? const Color(0xFF6366F1).withOpacity(0.5) : const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text('Select', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8))),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              onChanged: items.isEmpty ? null : onChanged,
              items: items.map((item) {
                String name = item['name'] ?? item['title'] ?? item['className'] ?? 'Unknown';
                if (item['section'] != null && item['section'].toString().trim().isNotEmpty) {
                  name += ' - ${item['section']}';
                }
                return DropdownMenuItem<String>(
                  value: item['id'].toString(),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: const Color(0xFF64748B)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name, 
                          style: GoogleFonts.poppins(
                            fontSize: 14, 
                            color: value == item['id']?.toString() ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                            fontWeight: value == item['id']?.toString() ? FontWeight.bold : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
