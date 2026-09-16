import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'single_student_result_screen.dart';
class AllStudentsResultScreen extends StatefulWidget {
  final String examId;
  final String classId;
  final String examName;
  final String className;
  final List<dynamic> students;

  const AllStudentsResultScreen({
    super.key,
    required this.examId,
    required this.classId,
    required this.examName,
    required this.className,
    required this.students,
  });

  @override
  State<AllStudentsResultScreen> createState() => _AllStudentsResultScreenState();
}

class _AllStudentsResultScreenState extends State<AllStudentsResultScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _resultsData = [];
  List<String> _uniqueSubjectIds = [];
  Map<String, String> _subjectNamesMap = {};

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    try {
      final res = await ApiService.getExamResults(widget.examId, classId: widget.classId);
      if (res['success']) {
        final List<dynamic> allResults = res['data'] ?? [];
        
        // Extract all unique subjects across all students
        Set<String> subNames = {};
        for (var r in allResults) {
          final smList = r['marks'] as List? ?? [];
          for (var sm in smList) {
            final subName = sm['subject']?.toString();
            if (subName != null) {
              subNames.add(subName);
              _subjectNamesMap[subName] = subName;
            }
          }
        }
        
        _uniqueSubjectIds = subNames.toList();
        _sortSubjects();
        
        if (mounted) {
          setState(() {
            _resultsData = allResults;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = res['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load results: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _sortSubjects() {
    final priorityMap = {
      'telugu': 1, 'tel': 1,
      'hindi': 2, 'hin': 2,
      'english': 3, 'eng': 3,
      'maths': 4, 'mat': 4, 'mathematics': 4,
      'physics': 5, 'physical science': 5, 'phy sci': 5, 'ps': 5,
      'biology': 6, 'biological science': 6, 'bio sci': 6, 'bs': 6,
      'science': 7,
      'chemistry': 8, 'chem': 8,
      'social': 9, 'soc': 9, 'social studies': 9,
    };

    _uniqueSubjectIds.sort((a, b) {
      final nameA = a.toLowerCase();
      final nameB = b.toLowerCase();
      
      int pA = 99;
      int pB = 99;
      
      for (var k in priorityMap.keys) {
        if (nameA.contains(k)) { pA = priorityMap[k]!; break; }
      }
      for (var k in priorityMap.keys) {
        if (nameB.contains(k)) { pB = priorityMap[k]!; break; }
      }

      if (pA != pB) return pA.compareTo(pB);
      return nameA.compareTo(nameB);
    });
  }

  String _getShortName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('telugu')) return 'TEL';
    if (lower.contains('hindi')) return 'HIN';
    if (lower.contains('english')) return 'ENG';
    if (lower.contains('maths') || lower.contains('mathematics')) return 'MAT';
    if (lower.contains('physical science') || lower.contains('physics')) return 'PHY';
    if (lower.contains('biological science') || lower.contains('biology')) return 'BIO';
    if (lower.contains('chemistry')) return 'CHE';
    if (lower.contains('science')) return 'SCI';
    if (lower.contains('social')) return 'SOC';
    
    // Default fallback to 3 chars
    if (name.length > 4) {
      return name.substring(0, 3).toUpperCase();
    }
    return name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class Results', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${widget.examName} - ${widget.className}', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
        : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: GoogleFonts.poppins(color: Colors.red)))
          : _resultsData.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_late_outlined, size: 64, color: const Color(0xFFCBD5E1).withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('No results found for this class.', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 15)),
                  ],
                ),
              )
            : _buildResultsTable(),
    );
  }

  Widget _buildResultsTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(50),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(1.5),
            },
            border: TableBorder.all(color: const Color(0xFFE2E8F0), width: 1.5),
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                children: [
                  _buildHeaderCell('S.No'),
                  _buildHeaderCell('Student Name', alignLeft: true),
                  _buildHeaderCell('Total Marks'),
                ],
              ),
              // Body
              ..._resultsData.asMap().entries.map((entry) {
                final index = entry.key;
                final r = entry.value;
                String name = r['name']?.toString() ?? 'Unknown';
                final total = r['total']?.toString() ?? '0';

                final rowColor = index % 2 == 0 
                    ? Colors.white 
                    : const Color(0xFFEEF2FF);

                return TableRow(
                  decoration: BoxDecoration(color: rowColor),
                  children: [
                    _buildCell('${index + 1}'),
                    _buildClickableNameCell(name, r),
                    _buildCell(total, isBold: true, color: const Color(0xFF4F46E5)),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClickableNameCell(String name, Map<String, dynamic> studentData) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SingleStudentResultScreen(
          examId: widget.examId,
          classId: widget.classId,
          studentId: studentData['studentId'].toString(),
          examName: widget.examName,
          studentData: studentData,
        )));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          name,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4F46E5),
            decoration: TextDecoration.underline,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool alignLeft = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  Widget _buildCell(String text, {bool alignLeft = false, bool isBold = false, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? const Color(0xFF475569),
        ),
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
      ),
    );
  }
}
