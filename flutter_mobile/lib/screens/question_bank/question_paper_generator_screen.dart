import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/latex_preview_widget.dart';
import '../../services/api_service.dart';

class QuestionPaperGeneratorScreen extends StatefulWidget {
  final String? paperId;

  const QuestionPaperGeneratorScreen({super.key, this.paperId});

  @override
  State<QuestionPaperGeneratorScreen> createState() => _QuestionPaperGeneratorScreenState();
}

class _QuestionPaperGeneratorScreenState extends State<QuestionPaperGeneratorScreen> {
  final TextEditingController _editorController = TextEditingController(
    text: '1. What is the capital of France?\n(A) London\n(B) Paris\n(C) Berlin\n(D) Madrid\n\n2. Solve for x: \$2x + 5 = 15\$\n(A) 2\n(B) 4\n(C) 5\n(D) 10',
  );

  bool _isDoubleColumn = false;
  String _examName = 'FINAL EXAMINATION';
  String _examSubject = 'GRAND TEST';
  String _examDate = '';
  String _maxMarks = '100';
  String _time = '75';
  String _instructions = 'Answer all questions.\nEach question carries equal marks.\nRead questions carefully before answering.';

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: Text(
          'AI Paper Generator',
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
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving paper...')));
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Editor Side
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
                      Text(
                        'Editor',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('Auto-Format'),
                        onPressed: () {
                          // Simple auto-format dummy
                          setState(() {});
                        },
                      ),
                    ],
                  ),
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

          // Preview Side
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
                      Text(
                        'Live Preview',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Text('Dual Column'),
                          Switch(
                            value: _isDoubleColumn,
                            onChanged: (val) {
                              setState(() => _isDoubleColumn = val);
                            },
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
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Header
                            Text(
                              _examName,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _examSubject,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
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
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: Text(_instructions, style: const TextStyle(fontStyle: FontStyle.italic)),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // LaTeX Preview Widget
                            LatexPreviewWidget(
                              text: _editorController.text,
                            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // AI Generation modal
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate with AI'),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
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
