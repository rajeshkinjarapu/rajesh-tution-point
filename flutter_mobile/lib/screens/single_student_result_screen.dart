import 'dart:ui' as ui;
import '../widgets/custom_network_image.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';

class SingleStudentResultScreen extends StatefulWidget {
  final String examId;
  final String classId;
  final String studentId;
  final String examName;
  final Map<String, dynamic>? studentData;

  const SingleStudentResultScreen({
    super.key,
    required this.examId,
    required this.classId,
    required this.studentId,
    required this.examName,
    this.studentData,
  });

  @override
  State<SingleStudentResultScreen> createState() => _SingleStudentResultScreenState();
}

class _SingleStudentResultScreenState extends State<SingleStudentResultScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _resultData;
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharing = false;



  @override
  void initState() {
    super.initState();
    _fetchResult();
  }

  Future<void> _fetchResult() async {
    try {
      final res = await ApiService.getExamResults(widget.examId, classId: widget.classId, includePhoto: true);
      if (res['success']) {
        final List<dynamic> allResults = res['data'] ?? [];
        final studentResult = allResults.firstWhere((r) => r['studentId']?.toString() == widget.studentId, orElse: () => null);
        if (mounted) {
          setState(() {
            _resultData = studentResult;
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
          _errorMessage = 'Failed to load result: $e';
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _shareResult() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      RenderRepaintBoundary boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        final directory = (await getApplicationDocumentsDirectory()).path;
        final file = File('$directory/student_result.png');
        await file.writeAsBytes(pngBytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Student Result - ${widget.examName}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Result Detail', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
          : _resultData == null
            ? Center(child: Text('No results found for this student.', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 15)))
            : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: const Color(0xFFF1F5F9), // Match screen background
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Premium Banner
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STUDENT RESULT',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.examName,
                                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStudentInfoCard(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.analytics_rounded, color: Color(0xFF4F46E5), size: 20),
                        const SizedBox(width: 8),
                        Text('Marks Breakdown', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildMarksTable(),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 12 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : _shareResult,
              icon: _isSharing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.share_rounded, color: Colors.white, size: 20),
              label: Text(_isSharing ? 'Preparing...' : 'Share Full Result', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentInfoCard() {
    final rollNo = _resultData!['rollNo']?.toString() ?? 'N/A';
    final name = _resultData!['name']?.toString() ?? 'Unknown';
    final fatherName = _resultData!['fatherName']?.toString() ?? 
                       _resultData!['user']?['fatherName']?.toString() ?? 
                       widget.studentData?['fatherName']?.toString() ?? 
                       widget.studentData?['user']?['fatherName']?.toString() ?? 
                       '-';
    final className = _resultData!['className']?.toString() ?? widget.studentData?['className']?.toString() ?? widget.studentData?['class_name']?.toString() ?? widget.studentData?['class']?.toString() ?? '-';
    
    final totalMarksObtained = _resultData!['total'] ?? 0;
    
    int totalMaxMarks = 0;
    final marksList = _resultData!['marks'] as List? ?? [];
    for(var m in marksList) { totalMaxMarks += (m['max'] as num?)?.toInt() ?? 100; }
    
    final percentage = _resultData!['percentage'] != null ? (_resultData!['percentage'] as num).toStringAsFixed(1) : '0.0';
    final grade = _resultData!['grade'] ?? _calculateGrade(totalMarksObtained, totalMaxMarks);
    final photoUrl = _resultData!['photo'] ?? widget.studentData?['photo'];

    // In case the photoUrl from result is an empty string
    final finalPhoto = (photoUrl == null || photoUrl.toString().isEmpty) ? null : photoUrl;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 6))],
        border: Border.all(color: const Color(0xFFEEF2FF), width: 2),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Details on the left
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('NAME', name, isName: true),
                    const SizedBox(height: 6),
                    _buildInfoRow('CLASS / SEC', className),
                    const SizedBox(height: 6),
                    _buildInfoRow('STUDENT ID', rollNo),
                    const SizedBox(height: 6),
                    _buildInfoRow('FATHER NAME', fatherName),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Rectangular Photo with premium border
              Container(
                width: 75,
                height: 95,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E7FF), width: 3),
                  boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildStudentImage(finalPhoto?.toString()),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEF2FF), thickness: 1.5),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Total Marks', '$totalMarksObtained / $totalMaxMarks', Icons.stars_rounded, const Color(0xFF3B82F6), const Color(0xFFDBEAFE)),
              _buildStatCard('Percentage', '$percentage%', Icons.pie_chart_rounded, const Color(0xFF10B981), const Color(0xFFD1FAE5)),
              _buildStatCard('Grade', grade, Icons.military_tech_rounded, _getGradeColor(grade), _getGradeColor(grade).withOpacity(0.15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isName = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 0.3),
          ),
        ),
        const Text(':  ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1), fontSize: 10)),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: isName ? 15 : 13, 
              fontWeight: isName ? FontWeight.w800 : FontWeight.w600, 
              color: isName ? const Color(0xFF4F46E5) : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color iconColor, Color bgColor) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  String _calculateGrade(num obtained, num max) {
    if (max == 0) return '-';
    double p = (obtained / max) * 100;
    if (p >= 95) return 'A+';
    if (p >= 90) return 'A';
    if (p >= 80) return 'B+';
    if (p >= 70) return 'B';
    if (p >= 60) return 'C+';
    if (p >= 50) return 'C';
    if (p >= 40) return 'D';
    return 'F';
  }

  Widget _buildMarksTable() {
    final marksList = List<Map<String, dynamic>>.from(_resultData!['marks'] ?? []);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFEEF2FF), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Colorful Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('SUBJECT', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5))),
                  Expanded(flex: 2, child: Text('OBTAINED', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5))),
                  Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5))),
                  Expanded(flex: 1, child: Text('GRADE', textAlign: TextAlign.right, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5))),
                ],
              ),
            ),
            ...marksList.asMap().entries.map((entry) {
              final index = entry.key;
              final sm = entry.value;
              final subName = sm['subject']?.toString().toUpperCase() ?? 'UNKNOWN';
              final marksObtained = sm['obtained'] ?? 0;
              final maxMarks = sm['max'] ?? 100;
              final g = _calculateGrade(marksObtained, maxMarks);
              final isPass = (marksObtained / maxMarks) >= 0.35;
              
              final rowColor = index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC);
              
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: rowColor,
                  border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3, 
                      child: Text(subName, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155)))
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('$marksObtained', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('$maxMarks', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPass ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFEF4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(g, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: isPass ? const Color(0xFF059669) : const Color(0xFFDC2626))),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+': case 'A': case 'O': return const Color(0xFF10B981);
      case 'B': case 'B+': return const Color(0xFF3B82F6);
      case 'C': case 'C+': return const Color(0xFFF59E0B);
      case 'D': return const Color(0xFFF97316);
      case 'F': case 'FAIL': return const Color(0xFFEF4444);
      default: return const Color(0xFF64748B);
    }
  }

  Widget _buildStudentImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return const Center(child: Icon(Icons.person_rounded, size: 36, color: Color(0xFF94A3B8)));
    }
    
    if (photoUrl.startsWith('data:image')) {
      try {
        final parts = photoUrl.split(',');
        if (parts.length > 1) {
          return Image.memory(
            base64Decode(parts[1]),
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => const Center(child: Icon(Icons.person_rounded, size: 36, color: Color(0xFF94A3B8))),
          );
        }
      } catch (e) {
        // ignore
      }
    }
    
    return CustomNetworkImage(
      ApiService.getImageUrl(photoUrl),
      fit: BoxFit.cover,
      headers: const {'ngrok-skip-browser-warning': '69420'},
      errorBuilder: (c, e, s) => const Center(child: Icon(Icons.person_rounded, size: 36, color: Color(0xFF94A3B8))),
    );
  }
}

