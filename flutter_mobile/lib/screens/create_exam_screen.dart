import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class CreateExamScreen extends StatefulWidget {
  final Map<String, dynamic>? existingExam;

  const CreateExamScreen({super.key, this.existingExam});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  bool _isLoading = false;
  String _examCategory = '';
  String _boardExamType = '';
  String _examName = '';
  String _examDate = DateTime.now().toIso8601String().split('T')[0];

  List<dynamic> _classes = [];
  Set<String> _selectedClassIds = {};

  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();

    if (widget.existingExam != null) {
      final ex = widget.existingExam!;
      _examName = ex['name'] ?? '';
      
      if (_examName.contains('JEE')) {
        _examCategory = 'JEE';
      } else if (['FA-', 'SA-', 'Pre-Final'].any((t) => _examName.contains(t))) {
        _examCategory = 'BOARD';
      }

      if (ex['examDate'] != null) {
        _examDate = ex['examDate'].toString().split('T')[0];
      }

      if (ex['classes'] != null) {
        for (var c in ex['classes']) {
          _selectedClassIds.add(c['id'].toString());
        }
      }

      if (ex['subjects'] != null) {
        for (var s in ex['subjects']) {
          _subjects.add({
            'name': s['name'] ?? '',
            'maxMarks': s['maxMarks'] ?? 100,
          });
        }
      }
    } else {
      // Default one subject
      _subjects.add({'name': '', 'maxMarks': 100});
    }
  }

  Future<void> _fetchClasses() async {
    final res = await ApiService.getClasses();
    if (mounted && res['success']) {
      setState(() {
        _classes = res['data'] ?? [];
      });
    }
  }

  double get _totalMarks {
    double sum = 0;
    for (var sub in _subjects) {
      sum += double.tryParse(sub['maxMarks'].toString()) ?? 0;
    }
    return sum;
  }

  Future<void> _saveExam() async {
    if (_examName.isEmpty || _selectedClassIds.isEmpty || _subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields and select at least one class and subject.')));
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'name': _examName,
      'classIds': _selectedClassIds.toList(),
      'examDate': _examDate,
      'maxMarks': _totalMarks,
      'subjects': _subjects.map((s) => {
        'name': s['name'],
        'maxMarks': int.tryParse(s['maxMarks'].toString()) ?? 100,
      }).toList(),
    };

    Map<String, dynamic> res;
    if (widget.existingExam != null) {
      res = await ApiService.updateExam(widget.existingExam!['id'].toString(), payload);
    } else {
      res = await ApiService.createExam(payload);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.existingExam != null ? 'Exam updated' : 'Exam created'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error saving exam'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: Text(
          widget.existingExam != null ? 'Edit Exam' : 'Create New Exam',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // General Details Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.description_outlined, color: Colors.indigo.shade600),
                            ),
                            const SizedBox(width: 12),
                            Text('General Details', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text('EXAM CATEGORY', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRadioCard('JEE', 'JEE Mains', 'Objective pattern', Icons.science),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRadioCard('BOARD', 'Board Exams', 'FA / SA / Finals', Icons.menu_book),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_examCategory == 'BOARD') ...[
                          Text('BOARD EXAM TYPE', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _boardExamType.isEmpty ? null : _boardExamType,
                            decoration: _inputDecoration(),
                            items: ['FA-1', 'FA-2', 'FA-3', 'FA-4', 'SA-1', 'SA-2', 'Pre-Final']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _boardExamType = val ?? '';
                                _examName = '${_boardExamType} Examination';
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        Text('EXAM NAME / TITLE', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _examName,
                          onChanged: (val) => _examName = val,
                          decoration: _inputDecoration(hint: 'e.g. Mid-Term 1'),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('START DATE', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: _examDate,
                                    onChanged: (val) => _examDate = val,
                                    decoration: _inputDecoration(icon: Icons.calendar_today),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('MAX MARKS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    key: ValueKey(_totalMarks), // Force rebuild when total changes
                                    initialValue: _totalMarks.toStringAsFixed(0),
                                    readOnly: true,
                                    decoration: _inputDecoration(icon: Icons.tag).copyWith(
                                      fillColor: Colors.grey.shade100,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Classes Selection
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.class_outlined, color: Colors.green.shade600),
                            ),
                            const SizedBox(width: 12),
                            Text('Applicable Classes', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _classes.map((c) {
                            final isSelected = _selectedClassIds.contains(c['id'].toString());
                            return FilterChip(
                              label: Text('${c['name']} - ${c['section']}', style: GoogleFonts.poppins(color: isSelected ? Colors.indigo.shade700 : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              selected: isSelected,
                              selectedColor: Colors.indigo.shade100,
                              checkmarkColor: Colors.indigo.shade700,
                              onSelected: (val) {
                                setState(() {
                                  if (val) _selectedClassIds.add(c['id'].toString());
                                  else _selectedClassIds.remove(c['id'].toString());
                                });
                              },
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subjects Configuration
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.library_books_outlined, color: Colors.amber.shade600),
                                ),
                                const SizedBox(width: 12),
                                Text('Subjects', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _subjects.add({'name': '', 'maxMarks': 100});
                                });
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Subject'),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._subjects.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final sub = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: sub['name'],
                                    onChanged: (val) => _subjects[idx]['name'] = val,
                                    decoration: _inputDecoration(hint: 'Subject Name'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: sub['maxMarks'].toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      _subjects[idx]['maxMarks'] = val;
                                      setState(() {}); // Trigger total marks recalculation
                                    },
                                    decoration: _inputDecoration(hint: 'Max Marks'),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _subjects.removeAt(idx);
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveExam,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        widget.existingExam != null ? 'Save Changes' : 'Create Exam',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildRadioCard(String value, String title, String subtitle, IconData icon) {
    final isSelected = _examCategory == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _examCategory = value;
          if (value == 'JEE') {
            _boardExamType = '';
            _examName = 'JEE Mains Model Examination';
          } else {
            _examName = '';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? (value == 'JEE' ? Colors.amber.shade50 : Colors.indigo.shade50) : Colors.white,
          border: Border.all(color: isSelected ? (value == 'JEE' ? Colors.amber.shade400 : Colors.indigo.shade400) : Colors.grey.shade200, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? (value == 'JEE' ? Colors.amber.shade600 : Colors.indigo.shade600) : Colors.grey.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade500, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo.shade500)),
    );
  }
}
