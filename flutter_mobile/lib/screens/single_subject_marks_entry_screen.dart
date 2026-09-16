import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class SingleSubjectMarksEntryScreen extends StatefulWidget {
  final String examId;
  final String classId;
  final List<dynamic> subjects;
  final List<dynamic> students;
  final String? initialSubjectId;

  const SingleSubjectMarksEntryScreen({
    super.key,
    required this.examId,
    required this.classId,
    required this.subjects,
    required this.students,
    this.initialSubjectId,
  });

  @override
  State<SingleSubjectMarksEntryScreen> createState() => _SingleSubjectMarksEntryScreenState();
}

class _SingleSubjectMarksEntryScreenState extends State<SingleSubjectMarksEntryScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  String _searchQuery = '';
  
  // Key format: "studentId_subjectId" -> Controller
  final Map<String, TextEditingController> _marksControllers = {};

  List<dynamic> _localSubjects = [];
  String? _selectedSubjectId;
  String _subjectName = 'All Subjects';

  @override
  void initState() {
    super.initState();
    
    // Sort subjects based on standard predefined order
    var sortedSubjects = List<dynamic>.from(widget.subjects);
    sortedSubjects.sort((a, b) {
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

    _localSubjects = sortedSubjects;
    if (_localSubjects.isNotEmpty && !_localSubjects.any((s) => s['id'] == 'ALL')) {
      _localSubjects.insert(0, {'id': 'ALL', 'name': 'All Subjects', 'maxMarks': 100});
    }
    
    if (_localSubjects.isNotEmpty) {
       _selectedSubjectId = widget.initialSubjectId ?? 'ALL';
       final subject = _localSubjects.firstWhere((s) => s['id'].toString() == _selectedSubjectId, orElse: () => null);
       _subjectName = subject != null ? subject['name']?.toString() ?? 'All Subjects' : 'All Subjects';
    }
    
    _initControllers();
    _fetchExistingMarks();
  }

  void _onSubjectChanged(String? subId) {
    if (subId == null) return;
    final subject = _localSubjects.firstWhere((s) => s['id'].toString() == subId, orElse: () => null);
    if (subject != null) {
      setState(() {
        _selectedSubjectId = subId;
        _subjectName = subject['name']?.toString() ?? 'Subject';
        _isLoading = true; // Show loading while re-initializing
      });
      
      // Re-init controllers for new selection
      _initControllers();
      // Fetch marks for new selection
      _fetchExistingMarks();
    }
  }

  void _initControllers() {
    _marksControllers.clear();
    for (var student in widget.students) {
      final sid = student['id'].toString();
      if (_selectedSubjectId == 'ALL') {
        for (var sub in _localSubjects.where((s) => s['id'] != 'ALL')) {
          _marksControllers["${sid}_${sub['id']}"] = TextEditingController();
        }
      } else {
        _marksControllers["${sid}_$_selectedSubjectId"] = TextEditingController();
      }
    }
  }

  double _getMaxMarksForSubject(String subId) {
    final sub = _localSubjects.firstWhere((s) => s['id'].toString() == subId, orElse: () => null);
    if (sub != null) {
      return double.tryParse(sub['maxMarks']?.toString() ?? '100') ?? 100.0;
    }
    return 100.0;
  }

  Future<void> _fetchExistingMarks() async {
    try {
      final res = await ApiService.getMarksForExam(widget.examId);
      if (res['success'] && res['data'] != null) {
        final existingMarks = res['data'] as List;
        for (var mark in existingMarks) {
          final sid = mark['studentId']?.toString();
          final subId = mark['subjectId']?.toString();
          String? matchedSubId = subId;
          if (sid != null && subId != null && !_marksControllers.containsKey('${sid}_$matchedSubId')) {
             final realSubName = mark['subject']?['name']?.toString().toLowerCase().trim();
             if (realSubName != null) {
               final matchedSub = _localSubjects.firstWhere(
                   (s) => s['name']?.toString().toLowerCase().trim() == realSubName, 
                   orElse: () => null
               );
               if (matchedSub != null) {
                 matchedSubId = matchedSub['id'].toString();
               }
             }
          }
          
          if (sid != null && matchedSubId != null) {
            final key = "${sid}_${matchedSubId}";
            if (_marksControllers.containsKey(key)) {
              _marksControllers[key]?.text = mark['marksObtained']?.toString() ?? '';
              if (mark['remarks']?.toString().toUpperCase() == 'AB' || mark['remarks']?.toString().toUpperCase() == 'ABSENT') {
                 _marksControllers[key]?.text = 'AB';
              }
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _marksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitMarks() async {
    setState(() => _isSubmitting = true);

    try {
      List<Map<String, dynamic>> finalMarks = [];
      String? errorMessage;
      
      _marksControllers.forEach((key, controller) {
        if (errorMessage != null) return; // Skip rest if error found
        
        final parts = key.split('_');
        final sid = parts[0];
        final subId = parts[1];
        final val = controller.text.trim();
        
        final maxM = _getMaxMarksForSubject(subId);

        if (val.isNotEmpty) {
          if (val.toUpperCase() != 'AB') {
            final parsed = double.tryParse(val);
            if (parsed == null) {
              errorMessage = 'Invalid marks entered.';
              return;
            }
            if (parsed > maxM) {
              final student = widget.students.firstWhere((s) => s['id'].toString() == sid, orElse: () => null);
              final sName = student?['user']?['name'] ?? 'Unknown';
              final sub = _localSubjects.firstWhere((s) => s['id'].toString() == subId, orElse: () => null);
              final subName = sub?['name'] ?? 'Subject';
              
              errorMessage = 'Marks for $sName in $subName cannot exceed $maxM.';
              return;
            }
          }

          finalMarks.add({
            'studentId': sid,
            'examId': widget.examId,
            'subjectId': subId,
            'marksObtained': val.toUpperCase() == 'AB' ? 0.0 : (double.tryParse(val) ?? 0.0),
            'maxMarks': maxM,
            'remarks': val.toUpperCase() == 'AB' ? 'Absent' : '',
          });
        }
      });

      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!), backgroundColor: Colors.red));
        setState(() => _isSubmitting = false);
        return;
      }

      if (finalMarks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No marks entered to save.'), backgroundColor: Colors.red));
        setState(() => _isSubmitting = false);
        return;
      }

      final res = await ApiService.uploadMarks({'marks': finalMarks});
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (res['success']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks saved successfully!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to save marks'), backgroundColor: Colors.red));
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
    final List<Map<String, dynamic>> studentsWithIndex = [];
    for (int i = 0; i < widget.students.length; i++) {
      studentsWithIndex.add({
        'student': widget.students[i],
        'originalIndex': i + 1,
      });
    }

    final filteredStudents = studentsWithIndex.where((s) {
      final name = s['student']['user']?['name']?.toString().toLowerCase() ?? '';
      final roll = s['student']['rollNo']?.toString().toLowerCase() ?? '';
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || roll.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom Premium Header
            Container(
              padding: const EdgeInsets.only(top: 16, bottom: 24, left: 16, right: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(color: Color(0x330F2027), blurRadius: 20, offset: Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_subjectName Marks',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold, 
                                fontSize: 24, 
                                color: Colors.white,
                                letterSpacing: 0.5
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter marks for ${filteredStudents.length} students',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w400, 
                                fontSize: 13, 
                                color: Colors.white.withOpacity(0.8)
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: Color(0xFFFFD700), size: 28),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search student by name or roll no...',
                        hintStyle: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 15),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Filters/Subject Selector
            if (_localSubjects.isNotEmpty)
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedSubjectId,
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2C5364)),
                      items: _localSubjects.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item['id']?.toString() ?? '',
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C5364).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  item['id'] == 'ALL' ? Icons.library_books_rounded : Icons.book_rounded, 
                                  size: 16, 
                                  color: const Color(0xFF2C5364)
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['name']?.toString() ?? 'Unknown',
                                  style: GoogleFonts.outfit(
                                    color: _selectedSubjectId == item['id']?.toString() ? const Color(0xFF2C5364) : const Color(0xFF1E293B),
                                    fontSize: 15,
                                    fontWeight: _selectedSubjectId == item['id']?.toString() ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: _onSubjectChanged,
                    ),
                  ),
                ),
              ),

            // Main Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2C5364)))
                  : filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
                                child: const Icon(Icons.person_search_rounded, size: 64, color: Color(0xFFCBD5E1)),
                              ),
                              const SizedBox(height: 24),
                              Text('No students found', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0),
                          itemCount: filteredStudents.length + 1,
                          itemBuilder: (context, index) {
                            if (index == filteredStudents.length) {
                              return SafeArea(
                                bottom: true,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 16, bottom: 24),
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF203A43).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _submitMarks,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 24),
                                              const SizedBox(width: 12),
                                              Text('SUBMIT MARKS', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.0)),
                                            ],
                                          ),
                                  ),
                                ),
                              );
                            }
                            final item = filteredStudents[index];
                            final student = item['student'];
                            final sNo = item['originalIndex'];
                            return _buildStudentCard(student, sNo);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int sNo) {
    final name = student['user']?['name'] ?? 'Unknown';
    final rollNo = student['rollNo'] ?? 'N/A';
    final sid = student['id'].toString();
    
    // Pick a vibrant color based on student index for avatar
    final colors = [
      const Color(0xFFE74C3C),
      const Color(0xFF9B59B6),
      const Color(0xFF3498DB),
      const Color(0xFF1ABC9C),
      const Color(0xFFF1C40F),
      const Color(0xFFE67E22),
    ];
    final avatarColor = colors[sNo % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: avatarColor.withOpacity(0.1), width: 1.5))
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: avatarColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
                    ]
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$sNo',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name, 
                        style: GoogleFonts.outfit(color: const Color(0xFF0F2027), fontWeight: FontWeight.w800, fontSize: 16)
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: avatarColor.withOpacity(0.3))
                        ),
                        child: Text(
                          'ID: $rollNo', 
                          style: GoogleFonts.outfit(color: avatarColor, fontSize: 11, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedSubjectId != 'ALL') ...[
                  const SizedBox(width: 12),
                  _buildMarksInput(sid, _selectedSubjectId!),
                ],
              ],
            ),
          ),
          
          if (_selectedSubjectId == 'ALL') ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 16) / 2;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ..._localSubjects.where((s) => s['id'] != 'ALL').map((sub) {
                        final subId = sub['id'].toString();
                        final subName = sub['name']?.toString() ?? 'Unknown';
                        return SizedBox(
                          width: itemWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.menu_book_rounded, size: 14, color: const Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      subName,
                                      style: GoogleFonts.outfit(color: const Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildMarksInput(sid, subId),
                            ],
                          ),
                        );
                      }).toList(),
                      // Total Widget
                      SizedBox(
                        width: itemWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.functions_rounded, size: 16, color: const Color(0xFF27AE60)),
                                const SizedBox(width: 4),
                                Text(
                                  'Total Score',
                                  style: GoogleFonts.outfit(color: const Color(0xFF27AE60), fontSize: 13, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF27AE60).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                                ]
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _calculateTotal(sid).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''),
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white, letterSpacing: 1.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              ),
            ),
          ]
        ],
      ),
    );
  }
  
  double _calculateTotal(String sid) {
    double total = 0;
    for (var sub in _localSubjects.where((s) => s['id'] != 'ALL')) {
      final key = "${sid}_${sub['id']}";
      final text = _marksControllers[key]?.text ?? '';
      if (text.isNotEmpty && text.toUpperCase() != 'AB') {
        total += double.tryParse(text) ?? 0;
      }
    }
    return total;
  }
  
  Widget _buildMarksInput(String sid, String subId) {
    final key = "${sid}_${subId}";
    final maxM = _getMaxMarksForSubject(subId);
    
    return SizedBox(
      width: _selectedSubjectId == 'ALL' ? double.infinity : 120,
      height: 54,
      child: TextField(
        controller: _marksControllers[key],
        keyboardType: TextInputType.text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w900, 
          fontSize: 18, 
          color: _marksControllers[key]?.text.toUpperCase() == 'AB' ? const Color(0xFFE74C3C) : const Color(0xFF0F2027)
        ),
        decoration: InputDecoration(
          labelText: 'Max: ${maxM.toInt()}',
          labelStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2C5364), width: 2.5)),
          suffixIcon: InkWell(
            onTap: () {
              setState(() {
                if (_marksControllers[key]?.text == 'AB') {
                  _marksControllers[key]?.text = '';
                } else {
                  _marksControllers[key]?.text = 'AB';
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _marksControllers[key]?.text == 'AB' ? const Color(0xFFE74C3C).withOpacity(0.15) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _marksControllers[key]?.text == 'AB' ? Icons.no_accounts_rounded : Icons.person_off_rounded, 
                size: 18, 
                color: _marksControllers[key]?.text == 'AB' ? const Color(0xFFE74C3C) : const Color(0xFF94A3B8)
              ),
            ),
          ),
        ),
        onChanged: (val) {
          setState(() {}); // trigger UI update for text color and total score
        },
      ),
    );
  }
}
