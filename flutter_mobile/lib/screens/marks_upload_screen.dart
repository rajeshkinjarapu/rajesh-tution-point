import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import 'single_subject_marks_entry_screen.dart';

class MarksUploadScreen extends StatefulWidget {
  final String? initialExamId;
  const MarksUploadScreen({super.key, this.initialExamId});

  @override
  State<MarksUploadScreen> createState() => _MarksUploadScreenState();
}

class _MarksUploadScreenState extends State<MarksUploadScreen> {
  List<dynamic> _exams = [];
  List<dynamic> _classes = [];
  List<dynamic> _students = [];
  List<dynamic> _subjects = [];

  String? _selectedExamId;
  String? _selectedClassId;
  String? _selectedSubjectId = 'ALL';
  
  bool _isLoadingDropdowns = true;
  bool _isLoadingStudents = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  final Map<String, TextEditingController> _marksControllers = {};
  double _maxMarks = 100;

  Map<String, dynamic>? _selectedExamData;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  @override
  void dispose() {
    for (var controller in _marksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchDropdownData() async {
    setState(() => _isLoadingDropdowns = true);
    try {
      final examsRes = await ApiService.getExams();
      final classesRes = await ApiService.getClasses();
      final subjectsRes = await ApiService.getSubjects();

      if (mounted) {
        setState(() {
          _exams = examsRes['success'] ? examsRes['data'] ?? [] : [];
          _classes = classesRes['success'] ? classesRes['data'] ?? [] : [];
          _subjects = subjectsRes['success'] ? subjectsRes['data'] ?? [] : [];
          
          if (widget.initialExamId != null) {
            _onExamSelected(widget.initialExamId);
          } else if (_selectedExamId != null) {
             _onExamSelected(_selectedExamId);
          }
          
          _isLoadingDropdowns = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load filters: $e';
          _isLoadingDropdowns = false;
        });
      }
    }
  }

  void _onExamSelected(String? examId) {
    if (examId == null) return;
    
    // Check if exam exists in list
    if (!_exams.any((e) => e['id']?.toString() == examId)) {
      _selectedExamId = null;
      _selectedExamData = null;
      return;
    }

    _selectedExamId = examId;
    _selectedExamData = _exams.firstWhere((e) => e['id']?.toString() == examId);
    
    // Validate selected class and subject against new exam
    if (_selectedClassId != null) {
      var examClasses = _selectedExamData!['classes'];
      if (examClasses is String) {
        try { examClasses = jsonDecode(examClasses); } catch(e) { examClasses = []; }
      }
      if (examClasses is List) {
        if (!examClasses.any((c) => c['id'].toString() == _selectedClassId)) {
          _selectedClassId = null;
          _students = [];
        }
      } else {
        _selectedClassId = null;
        _students = [];
      }
    }
    
    if (_selectedSubjectId != 'ALL') {
      var examSubjects = _selectedExamData!['subjects'];
      if (examSubjects is String) {
        try { examSubjects = jsonDecode(examSubjects); } catch(e) { examSubjects = []; }
      }
      if (examSubjects is List) {
        if (!examSubjects.any((s) => s['id'].toString() == _selectedSubjectId)) {
          _selectedSubjectId = 'ALL';
        }
      } else {
        _selectedSubjectId = 'ALL';
      }
    }
  }

  Future<void> _fetchStudentsForClass() async {
    if (_selectedClassId == null) return;
    setState(() => _isLoadingStudents = true);

    try {
      final res = await ApiService.getStudents(classId: _selectedClassId);
      
      if (!mounted) return;
      
      if (res['success']) {
        List<dynamic> fetchedStudents = [];
        if (res['data'] is List) {
          fetchedStudents = List<dynamic>.from(res['data']);
        }
        
        final Map<String, TextEditingController> newControllers = {};
        for (var s in fetchedStudents) {
          if (s != null && s['id'] != null) {
            newControllers[s['id'].toString()] = TextEditingController();
          }
        }
        
        setState(() {
          _students = fetchedStudents;
          _marksControllers.clear();
          _marksControllers.addAll(newControllers);
          _isLoadingStudents = false;
        });
      } else {
        setState(() => _isLoadingStudents = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStudents = false);
      }
    }
  }

  Future<void> _submitMarks() async {
    if (_selectedExamId == null || _selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Exam and Class'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Gather marks
      List<Map<String, dynamic>> marksData = [];
      for (var s in _students) {
        final sid = s['id'].toString();
        final val = _marksControllers[sid]?.text ?? '';
        if (val.isNotEmpty) {
          marksData.add({
            'studentId': sid,
            'examId': _selectedExamId,
            'subjectId': _selectedSubjectId,
            'marksObtained': double.tryParse(val) ?? 0.0,
            'maxMarks': _maxMarks,
            'remarks': '',
          });
        }
      }

      if (marksData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter marks for at least one student'), backgroundColor: Colors.red));
        setState(() => _isSubmitting = false);
        return;
      }

      final payload = {
        'marks': marksData,
      };

      final res = await ApiService.uploadMarks(payload);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (res['success']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks uploaded successfully!'), backgroundColor: Colors.green));
          _marksControllers.forEach((_, c) => c.clear());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Upload failed'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slight gray background
      drawer: const AppDrawer(currentRoute: 'marks'),
      appBar: AppBar(
        title: Text('Upload Marks', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
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
      body: _isLoadingDropdowns
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)))
              : Column(
                  children: [
                _buildFiltersPanel(),
                
                // Show Proceed Button only when all 3 filters are selected
                if (_selectedExamId != null && _selectedClassId != null)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E7FF),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                                ],
                              ),
                              child: const Icon(Icons.check_circle_outline_rounded, size: 64, color: Color(0xFF6366F1)),
                            ),
                            const SizedBox(height: 24),
                            Text('Ready to Enter Marks', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                            const SizedBox(height: 8),
                            Text('Click below to open the student list', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B))),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoadingStudents ? null : () {
                                  final subjects = _getFilteredSubjects();
                                  if (subjects.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No subjects found for this exam.'), backgroundColor: Colors.red));
                                    return;
                                  }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SingleSubjectMarksEntryScreen(
                                          examId: _selectedExamId!,
                                          classId: _selectedClassId!,
                                          subjects: subjects,
                                          students: _students,
                                          initialSubjectId: _selectedSubjectId,
                                        ),
                                      ),
                                    );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isLoadingStudents
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Proceed to Enter Marks', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                                      ],
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_alt_outlined, size: 64, color: const Color(0xFFCBD5E1).withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text('Select filters to continue', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 15)),
                        ],
                      ),
                    ),
                  )
              ],
            ),
    );
  }

  List<dynamic> _getFilteredSubjects() {
    if (_selectedExamData != null && _selectedExamData!['subjects'] != null) {
      var examSubjects = _selectedExamData!['subjects'];
      if (examSubjects is String) {
        try { examSubjects = jsonDecode(examSubjects); } catch(e) { examSubjects = []; }
      }
      
      if (examSubjects is Map) {
        if (_selectedClassId != null && examSubjects['classConfigs'] != null && examSubjects['classConfigs'] is List) {
          final configs = examSubjects['classConfigs'] as List<dynamic>;
          final matchingCfg = configs.firstWhere((c) => c['classId'] == _selectedClassId, orElse: () => null);
          if (matchingCfg != null && matchingCfg['subjects'] != null) {
            examSubjects = matchingCfg['subjects'];
          } else {
            examSubjects = [];
          }
        } else if (examSubjects['globalSubjects'] != null) {
          examSubjects = examSubjects['globalSubjects'];
        }
      }

      if (examSubjects is List) {
        var subjects = List<dynamic>.from(examSubjects);

        // *** KEY FIX: Replace fake IDs with real DB Subject IDs by name-matching ***
        final realSubjectsForClass = _subjects.where(
          (s) => s['classId']?.toString() == _selectedClassId
        ).toList();

        subjects = subjects.map((examSub) {
          final examSubName = examSub['name']?.toString().toLowerCase().trim() ?? '';
          final realMatch = realSubjectsForClass.firstWhere(
            (rs) => rs['name']?.toString().toLowerCase().trim() == examSubName,
            orElse: () => null,
          );
          if (realMatch != null) {
            // Return subject with REAL database ID
            return {
              'id': realMatch['id'],
              'name': examSub['name'],
              'maxMarks': examSub['maxMarks'] ?? realMatch['maxMarks'] ?? 100,
            };
          }
          return examSub;
        }).toList();

        subjects.sort((a, b) {
          final nameA = (a['name']?.toString() ?? '').toLowerCase();
          final nameB = (b['name']?.toString() ?? '').toLowerCase();
          
          int getOrder(String name) {
            if (name.contains('tel')) return 1;
            if (name.contains('hin')) return 2;
            if (name.contains('eng')) return 3;
            if (name.contains('mat')) return 4;
            if (name.contains('sci') || name.contains('evs')) return 5;
            if (name.contains('soc')) return 6;
            return 99;
          }
          
          return getOrder(nameA).compareTo(getOrder(nameB));
        });
        return subjects;
      }
    }
    return [];
  }


  Widget _buildFiltersPanel() {
    List<dynamic> filteredClasses = [];
    List<dynamic> filteredSubjects = _getFilteredSubjects();
    
    if (_selectedExamData != null) {
      if (_selectedExamData!['classes'] != null) {
        var examClasses = _selectedExamData!['classes'];
        if (examClasses is String) {
          try { examClasses = jsonDecode(examClasses); } catch(e) { examClasses = []; }
        }
        if (examClasses is List) {
          final examClassIds = examClasses.map((c) => c['id'].toString()).toSet();
          filteredClasses = _classes.where((c) => examClassIds.contains(c['id'].toString())).toList();
        }
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          _buildDropdown(
            hint: _exams.isEmpty ? 'No Exams Found' : 'Select Exam',
            value: _selectedExamId,
            items: _exams,
            icon: Icons.assignment_rounded,
            onChanged: (val) {
              setState(() { 
                _onExamSelected(val);
              });
              if (_selectedClassId != null) {
                _fetchStudentsForClass();
              }
            },
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildDropdown(
                hint: _selectedExamId == null ? 'Select Exam First' : 'Class',
                value: _selectedClassId,
                items: filteredClasses,
                icon: Icons.class_rounded,
                onChanged: _selectedExamId == null ? null : (val) {
                  setState(() { _selectedClassId = val; });
                  _fetchStudentsForClass();
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<dynamic> items,
    required IconData icon,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: value != null ? const Color(0xFF6366F1).withOpacity(0.5) : const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF64748B)),
              const SizedBox(width: 10),
              Text(hint, style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14)),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
          items: items.map<DropdownMenuItem<String>>((item) {
            String label = item['name'] ?? item['className'] ?? 'Unknown';
            if (item['section'] != null && item['section'].toString().trim().isNotEmpty) {
              label += ' - ${item['section']}';
            }
            return DropdownMenuItem<String>(
              value: item['id']?.toString() ?? '',
              child: Text(
                label, 
                style: GoogleFonts.poppins(
                  color: value == item['id']?.toString() ? const Color(0xFF6366F1) : const Color(0xFF1E293B), 
                  fontSize: 14,
                  fontWeight: value == item['id']?.toString() ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final name = student['user']?['name'] ?? 'Unknown';
        final rollNo = student['rollNo'] ?? 'N/A';
        final sid = student['id'].toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              // Initials Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: GoogleFonts.poppins(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('Roll: $rollNo', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Marks Input
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _marksControllers[sid],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: '-',
                    hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
