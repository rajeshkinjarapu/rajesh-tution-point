import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/latex_preview_widget.dart';
import '../../services/api_service.dart';

class PaperSection {
  String id;
  String name;
  String instructions;
  String marksPerQuestion;
  String totalQuestions;
  String content;

  PaperSection({
    required this.id,
    required this.name,
    required this.instructions,
    required this.marksPerQuestion,
    required this.totalQuestions,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'instructions': instructions,
        'marksPerQuestion': marksPerQuestion,
        'totalQuestions': totalQuestions,
        'content': content,
      };

  factory PaperSection.fromJson(Map<String, dynamic> json) {
    return PaperSection(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      instructions: json['instructions'] ?? '',
      marksPerQuestion: json['marksPerQuestion'] ?? '',
      totalQuestions: json['totalQuestions'] ?? '',
      content: json['content'] ?? '',
    );
  }
}

class NavodayaPaperGeneratorScreen extends StatefulWidget {
  final String? paperId;

  const NavodayaPaperGeneratorScreen({super.key, this.paperId});

  @override
  State<NavodayaPaperGeneratorScreen> createState() => _NavodayaPaperGeneratorScreenState();
}

class _NavodayaPaperGeneratorScreenState extends State<NavodayaPaperGeneratorScreen> {
  final TextEditingController _editorController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Paper Settings
  String _examName = 'FINAL EXAMINATION';
  String _examSubject = 'GRAND TEST';
  String _examDate = '';
  String _maxMarks = '100';
  String _time = '75';
  String _instructions = 'Answer all questions.\nEach question carries equal marks.';

  // Section Mode State
  bool _isSectionMode = true;
  List<PaperSection> _sections = [
    PaperSection(
      id: 'sec-${DateTime.now().millisecondsSinceEpoch}',
      name: 'SECTION - I',
      instructions: 'Note: (i) Answer ALL the following questions.\n(ii) Each question carries 1 Mark.',
      marksPerQuestion: '1',
      totalQuestions: '12',
      content: '1. What is 25% of 200?\n(A) 25\n(B) 50\n(C) 75\n(D) 100\n\n2. Solve for x: \$2x + 5 = 15\$\n(A) 2\n(B) 4\n(C) 5\n(D) 10',
    )
  ];
  String? _activeSectionId;
  
  bool _isDoubleColumn = false;

  @override
  void initState() {
    super.initState();
    _activeSectionId = _sections.first.id;
    if (widget.paperId != null) {
      _loadPaper();
    } else {
      _syncActiveSectionContent();
    }
  }

  void _syncActiveSectionContent() {
    if (_isSectionMode) {
      final activeSec = _sections.firstWhere((s) => s.id == _activeSectionId, orElse: () => _sections.first);
      _editorController.text = activeSec.content;
    }
  }

  Future<void> _loadPaper() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getGeneratedPaperById(widget.paperId!);
      if (res['examName'] != null) _examName = res['examName'];
      if (res['examSubject'] != null) _examSubject = res['examSubject'];
      if (res['examDate'] != null) _examDate = res['examDate'];
      if (res['time'] != null) _time = res['time'];
      if (res['instructions'] != null) _instructions = res['instructions'];
      if (res['maxMarks'] != null) _maxMarks = res['maxMarks'].toString();

      final rawContent = res['content'] ?? '';
      final RegExp boardExamJsonRegex = RegExp(r'^<!--BOARD_EXAM_JSON:(.*?)-->$');
      final match = boardExamJsonRegex.firstMatch(rawContent);

      if (match != null) {
        final parsed = jsonDecode(match.group(1)!);
        if (parsed['sections'] != null && (parsed['sections'] as List).isNotEmpty) {
          _sections = (parsed['sections'] as List).map((s) => PaperSection.fromJson(s)).toList();
          _isSectionMode = true;
          _activeSectionId = _sections.first.id;
        } else {
          _isSectionMode = false;
          _editorController.text = parsed['text'] ?? '';
        }
      } else {
        // Fallback for old simple format
        _isSectionMode = false;
        String text = rawContent;
        if (text.contains('<!--INLINE_IMAGES:')) {
          text = text.substring(0, text.indexOf('\n<!--INLINE_IMAGES:'));
        }
        text = text.replaceAll(RegExp(r'\[IMG:[a-z0-9]+\]'), '');
        _editorController.text = text;
      }
      _syncActiveSectionContent();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load paper: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePaper() async {
    setState(() => _isSaving = true);
    try {
      String serializedContent = '';
      if (_isSectionMode) {
        // Save current editor text into active section before serializing
        final activeIdx = _sections.indexWhere((s) => s.id == _activeSectionId);
        if (activeIdx != -1) {
          _sections[activeIdx].content = _editorController.text;
        }
        final payloadObj = {
          'sections': _sections.map((s) => s.toJson()).toList(),
          'inlineImages': {},
        };
        serializedContent = '<!--BOARD_EXAM_JSON:${jsonEncode(payloadObj)}-->';
      } else {
        final payloadObj = {
          'text': _editorController.text,
          'inlineImages': {},
        };
        serializedContent = '<!--BOARD_EXAM_JSON:${jsonEncode(payloadObj)}-->';
      }

      final payload = {
        'examName': _examName,
        'examClass': '10', // Default or need prompt
        'examSubject': _examSubject,
        'examDate': _examDate,
        'time': _time,
        'instructions': _instructions,
        'content': serializedContent,
      };

      if (widget.paperId != null) {
        await ApiService.updateGeneratedPaper(widget.paperId!, payload);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paper updated successfully!')));
      } else {
        await ApiService.saveGeneratedPaper(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paper saved successfully!')));
          Navigator.pop(context, true); // Return to list and refresh
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save paper: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: Text(
          'Question Paper Generator',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
            tooltip: 'Paper Settings',
          ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _savePaper,
            icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : (widget.paperId != null ? 'Update' : 'Save')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Editor
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Editor', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      OutlinedButton.icon(
                        icon: Icon(_isSectionMode ? Icons.view_headline : Icons.view_agenda, size: 16),
                        label: Text(_isSectionMode ? 'Switch to Simple Mode' : 'Switch to Section Mode'),
                        style: OutlinedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          setState(() {
                            _isSectionMode = !_isSectionMode;
                            if (_isSectionMode && _sections.isEmpty) {
                              _sections.add(PaperSection(
                                id: 'sec-${DateTime.now().millisecondsSinceEpoch}',
                                name: 'SECTION - I',
                                instructions: 'Note: Answer all questions.',
                                marksPerQuestion: '1',
                                totalQuestions: '10',
                                content: _editorController.text,
                              ));
                              _activeSectionId = _sections.first.id;
                            }
                            _syncActiveSectionContent();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isSectionMode) ...[
                    // Sections Tabs
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _sections.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _sections.length) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: TextButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Section'),
                                onPressed: () {
                                  setState(() {
                                    final newSec = PaperSection(
                                      id: 'sec-${DateTime.now().millisecondsSinceEpoch}',
                                      name: 'SECTION - NEW',
                                      instructions: 'Note: Answer all questions.',
                                      marksPerQuestion: '1',
                                      totalQuestions: '10',
                                      content: '',
                                    );
                                    _sections.add(newSec);
                                    // Save current editor text
                                    final activeIdx = _sections.indexWhere((s) => s.id == _activeSectionId);
                                    if (activeIdx != -1) _sections[activeIdx].content = _editorController.text;
                                    
                                    _activeSectionId = newSec.id;
                                    _editorController.text = '';
                                  });
                                },
                              ),
                            );
                          }
                          final sec = _sections[index];
                          final isActive = sec.id == _activeSectionId;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(sec.name.isNotEmpty ? sec.name : 'Unnamed'),
                              selected: isActive,
                              selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isActive ? const Color(0xFF6366F1) : Colors.black87,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                if (selected && !isActive) {
                                  setState(() {
                                    // Save current editor text
                                    final activeIdx = _sections.indexWhere((s) => s.id == _activeSectionId);
                                    if (activeIdx != -1) _sections[activeIdx].content = _editorController.text;
                                    
                                    _activeSectionId = sec.id;
                                    _editorController.text = sec.content;
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Active Section Properties
                    if (_activeSectionId != null) ...[
                      Builder(
                        builder: (context) {
                          final activeSec = _sections.firstWhere((s) => s.id == _activeSectionId);
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: activeSec.name,
                                      decoration: const InputDecoration(
                                        labelText: 'Section Name',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) => setState(() => activeSec.name = val),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: activeSec.totalQuestions,
                                      decoration: const InputDecoration(
                                        labelText: 'Total Qs',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) => setState(() => activeSec.totalQuestions = val),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: activeSec.marksPerQuestion,
                                      decoration: const InputDecoration(
                                        labelText: 'Marks/Q',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) => setState(() => activeSec.marksPerQuestion = val),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: activeSec.instructions,
                                decoration: const InputDecoration(
                                  labelText: 'Instructions',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                                onChanged: (val) => setState(() => activeSec.instructions = val),
                              ),
                              if (_sections.length > 1)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                    label: const Text('Delete Section', style: TextStyle(color: Colors.red)),
                                    onPressed: () {
                                      setState(() {
                                        _sections.removeWhere((s) => s.id == _activeSectionId);
                                        _activeSectionId = _sections.first.id;
                                        _editorController.text = _sections.first.content;
                                      });
                                    },
                                  ),
                                )
                            ],
                          );
                        }
                      ),
                    ],
                  ],
                  
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _editorController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: GoogleFonts.firaCode(fontSize: 14),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                          hintText: 'Type your questions here using LaTeX...',
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Container(width: 1, color: Colors.grey.shade300),

          // Right Side: Preview
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Live Preview', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Text('Dual Column'),
                          Switch(
                            value: _isDoubleColumn,
                            onChanged: (val) => setState(() => _isDoubleColumn = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Header
                            Text(_examName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            Text(_examSubject, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Date: ${_examDate.isEmpty ? '________' : _examDate}'),
                                Text('Marks: $_maxMarks'),
                                Text('Time: $_time mins'),
                              ],
                            ),
                            const Divider(thickness: 2, height: 24),
                            if (_instructions.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                                child: Text(_instructions, style: const TextStyle(fontStyle: FontStyle.italic)),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // LaTeX Preview Widget
                            if (_isSectionMode)
                              ..._buildSectionPreview()
                            else
                              LatexPreviewWidget(text: _editorController.text),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSectionPreview() {
    List<Widget> widgets = [];
    // temporarily sync editor text so preview is accurate
    final activeIdx = _sections.indexWhere((s) => s.id == _activeSectionId);
    if (activeIdx != -1) _sections[activeIdx].content = _editorController.text;

    for (var sec in _sections) {
      if (sec.name.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(sec.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        );
      }
      if (sec.instructions.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(sec.instructions, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
          ),
        );
      }
      if (sec.content.isNotEmpty) {
        widgets.add(LatexPreviewWidget(text: sec.content));
      }
    }
    return widgets;
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Paper Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Exam Name'),
                  onChanged: (val) => _examName = val,
                  controller: TextEditingController(text: _examName),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Subject'),
                  onChanged: (val) => _examSubject = val,
                  controller: TextEditingController(text: _examSubject),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Marks'),
                  onChanged: (val) => _maxMarks = val,
                  controller: TextEditingController(text: _maxMarks),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Time (mins)'),
                  onChanged: (val) => _time = val,
                  controller: TextEditingController(text: _time),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Global Instructions'),
                  maxLines: 3,
                  onChanged: (val) => _instructions = val,
                  controller: TextEditingController(text: _instructions),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
