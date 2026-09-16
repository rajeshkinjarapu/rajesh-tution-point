import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../widgets/progress_card_native.dart';

class SingleProgressCardScreen extends StatefulWidget {
  final String examId;
  final String classId;
  final String studentId;
  final Map<String, dynamic>? studentData;
  final String examName;
  final String className;
  final bool autoShare;

  const SingleProgressCardScreen({
    super.key,
    required this.examId,
    required this.classId,
    required this.studentId,
    this.studentData,
    required this.examName,
    required this.className,
    this.autoShare = false,
  });

  @override
  State<SingleProgressCardScreen> createState() => _SingleProgressCardScreenState();
}

class _SingleProgressCardScreenState extends State<SingleProgressCardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _mappedData;
  Map<String, dynamic>? _settings;

  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception("Authentication required");

      final baseUrl = 'http://YOUR_LOCAL_IP:19998/api';
      
      // Fetch settings
      final settingsRes = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      // Fetch exam results
      final resultsRes = await http.get(
        Uri.parse('$baseUrl/exams/${widget.examId}/results?classId=${widget.classId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (settingsRes.statusCode == 200) {
        final settingsJson = jsonDecode(settingsRes.body);
        _settings = settingsJson['data'] ?? {};
      }

      if (resultsRes.statusCode == 200) {
        final resultsJson = jsonDecode(resultsRes.body);
        final List<dynamic> allStudents = resultsJson['data'] ?? [];
        
        final targetStudent = allStudents.firstWhere(
          (s) => s['studentId'].toString() == widget.studentId.toString(),
          orElse: () => null,
        );

        if (targetStudent == null) {
          throw Exception("Student result not found in this exam");
        }

        // Map backend data
        _mappedData = {
          'studentName': targetStudent['name'],
          'rollNo': targetStudent['rollNo'],
          'className': (targetStudent['className']?.toString() ?? '').split('-').isNotEmpty ? targetStudent['className']?.toString().split('-')[0].trim() : widget.className,
          'section': (targetStudent['className']?.toString() ?? '').split('-').length > 1 ? targetStudent['className']?.toString().split('-')[1].trim() : "",
          'mobile': targetStudent['mobile'],
          'rank': targetStudent['rank'],
          'photo': targetStudent['photo'] != null ? 'http://YOUR_LOCAL_IP:19998${targetStudent['photo']}' : '',
          'total': targetStudent['total'],
          'academicYear': targetStudent['academicYear'],
          'location': "Narasannapeta", 
          'marks': targetStudent['marks'] ?? [],
          'examName': widget.examName,
        };

      } else {
        throw Exception("Failed to load results. Server returned ${resultsRes.statusCode}");
      }
      
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (widget.autoShare && _error == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _shareOrDownload(true);
          });
        }
      }
    }
  }

  Future<void> _shareOrDownload(bool isShare) async {
    try {
      // 1. Capture the widget as an image
      RenderRepaintBoundary boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // Use pixel ratio for high quality
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2. Create PDF
      final pdf = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      final String rawName = _mappedData?['studentName']?.toString() ?? 'Student';
      final String cleanName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').replaceAll(RegExp(r'_+'), '_');
      final String fileName = '${cleanName}_ProgressCard.pdf';

      // 3. Save to temp dir
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (isShare) {
        // Share PDF
        await Share.shareXFiles([XFile(file.path)], text: 'Progress Card for ${_mappedData?['studentName']}');
      } else {
        // Save to downloads (or just share it as save)
        // Since saving to downloads directly requires specific permissions on Android 10+,
        // we'll just use Share to allow the user to save it to their preferred location
        await Share.shareXFiles([XFile(file.path)], text: 'Save Progress Card');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Progress Card', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF2E2A66), Color(0xFF222854)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchData,
          )
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 50, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Failed to load data', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchData,
                            child: const Text('Try Again'),
                          )
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: RepaintBoundary(
                                key: _cardKey,
                                child: ProgressCardNative(
                                  data: _mappedData ?? {},
                                  settings: _settings ?? {},
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Bottom Action Buttons
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                          ]
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _shareOrDownload(true),
                                icon: const Icon(Icons.share_rounded, size: 18),
                                label: const Text('Share'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  foregroundColor: const Color(0xFF2E2A66),
                                  side: const BorderSide(color: Color(0xFF2E2A66)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _shareOrDownload(false),
                                icon: const Icon(Icons.download_rounded, size: 18),
                                label: const Text('Download'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
      ),
    );
  }
}
