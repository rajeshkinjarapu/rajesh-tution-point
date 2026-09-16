import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'upload_question_paper_screen.dart';

class QuestionPapersScreen extends StatefulWidget {
  const QuestionPapersScreen({super.key});

  @override
  State<QuestionPapersScreen> createState() => _QuestionPapersScreenState();
}

class _QuestionPapersScreenState extends State<QuestionPapersScreen> {
  List<dynamic> _papers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _userRole = '';
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _initRole();
  }

  Future<void> _initRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      setState(() {
        _userRole = jsonDecode(userStr)['role'] ?? '';
      });
    }
    _fetchPapers();
  }

  Future<void> _fetchPapers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await ApiService.getQuestionPapers();
      if (res['success']) {
        _papers = res['data'] ?? [];
        if (_userRole == 'ADMIN' || _userRole == 'SUPER_ADMIN') {
          final statsRes = await ApiService.getQuestionPaperDashboardStats();
          if (statsRes['success']) {
            _stats = statsRes['data'];
          }
        }
      } else {
        _errorMessage = res['message'] ?? 'Failed to load question papers';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    String finalUrl = url.trim();
    if (!finalUrl.startsWith('http')) {
      if (finalUrl.startsWith('/')) {
        finalUrl = '${ApiService.baseUrl}$finalUrl';
      } else {
        finalUrl = '${ApiService.baseUrl}/$finalUrl';
      }
    }

    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the file link: $finalUrl')),
        );
      }
    }
  }

  Future<void> _approvePaper(String id) async {
    final res = await ApiService.approveQuestionPaper(id);
    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paper approved successfully'), backgroundColor: Colors.green));
      _fetchPapers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to approve paper'), backgroundColor: Colors.red));
    }
  }

  Future<void> _rejectPaper(String id) async {
    final res = await ApiService.rejectQuestionPaper(id);
    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paper rejected successfully'), backgroundColor: Colors.red));
      _fetchPapers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to reject paper'), backgroundColor: Colors.red));
    }
  }

  Future<void> _publishPaper(String id) async {
    final res = await ApiService.publishQuestionPaper(id);
    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paper published successfully'), backgroundColor: Colors.green));
      _fetchPapers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to publish paper'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deletePaper(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Paper'),
        content: const Text('Are you sure you want to delete this question paper?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final res = await ApiService.deleteQuestionPaper(id);
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paper deleted'), backgroundColor: Colors.green));
        _fetchPapers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to delete paper'), backgroundColor: Colors.red));
      }
    }
  }

  void _showAnswerKeyUpdateSheet(String id, String? currentKey, String? currentUrl) {
    final keyController = TextEditingController(text: currentKey);
    final urlController = TextEditingController(text: currentUrl);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Answer Key', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: keyController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Type Answer Key',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: 'Answer Key PDF Link (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        setModalState(() => isSaving = true);
                        final res = await ApiService.updateAnswerKey(
                          id, 
                          keyController.text.trim(), 
                          urlController.text.trim()
                        );
                        setModalState(() => isSaving = false);
                        if (res['success']) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Answer key updated successfully'), backgroundColor: Colors.green));
                          _fetchPapers();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to update key'), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Answer Key', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showAnswerKeyDialog(String title, String answerKeyText) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.key, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Answer Key',
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                            ),
                            Text(
                              title,
                              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SelectableText(
                          answerKeyText,
                          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF334155), height: 1.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardStats() {
    if (_stats == null) return const SizedBox.shrink();
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 8, top: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildStatCard('Total Papers', _stats!['totalPapers']?.toString() ?? '0', const Color(0xFF6366F1), Icons.file_copy_rounded),
          const SizedBox(width: 12),
          _buildStatCard('Keys Uploaded', _stats!['answerKeys']?.toString() ?? '0', const Color(0xFF10B981), Icons.key_rounded),
          const SizedBox(width: 12),
          _buildStatCard('Published', _stats!['publishedPapers']?.toString() ?? '0', const Color(0xFF06B6D4), Icons.check_circle_rounded),
          const SizedBox(width: 12),
          _buildStatCard('Scheduled', _stats!['scheduledPapers']?.toString() ?? '0', const Color(0xFFF59E0B), Icons.watch_later_rounded),
          const SizedBox(width: 12),
          _buildStatCard('Total Qs', _stats!['totalQuestions']?.toString() ?? '0', const Color(0xFFEC4899), Icons.help_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label.toUpperCase(), style: GoogleFonts.poppins(fontSize: 8, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.outfit(fontSize: 22, color: const Color(0xFF1E293B), fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _userRole == 'ADMIN' || _userRole == 'SUPER_ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Question Papers',
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
        elevation: 0,
      ),
      body: SafeArea(
        bottom: true,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(color: Colors.blueGrey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchPapers,
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchPapers,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isAdmin) _buildDashboardStats(),
                        Expanded(
                          child: _papers.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.6,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(28),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6366F1).withOpacity(0.08),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.file_copy_rounded, 
                                                size: 72, 
                                                color: Color(0xFF6366F1)
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Text(
                                              'No Question Papers',
                                              style: GoogleFonts.outfit(
                                                fontSize: 22, 
                                                fontWeight: FontWeight.bold, 
                                                color: const Color(0xFF1E293B)
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 40),
                                              child: Text(
                                                'There are currently no question papers uploaded for your classes.',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14, 
                                                  color: const Color(0xFF64748B),
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _papers.length,
                                  itemBuilder: (context, index) {
                                    final paper = _papers[index];
                                    final title = paper['title'] ?? 'Untitled Paper';
                                    final examName = paper['exam']?['name'];
                                    final subject = paper['subject']?['name'] ?? 'All Subjects';
                                    final className = paper['class'] != null 
                                        ? '${paper['class']['name']}-${paper['class']['section']}' 
                                        : 'All Classes';
                                    final fileUrl = paper['fileUrl'];
                                    final answerKeyUrl = paper['answerKeyUrl'];
                                    final answerKey = paper['answerKey'];
                                    final status = paper['status'] ?? 'PENDING_APPROVAL';

                                    Color statusColor = Colors.amber;
                                    if (status == 'PUBLISHED') {
                                      statusColor = Colors.green;
                                    } else if (status == 'APPROVED') {
                                      statusColor = Colors.blue;
                                    } else if (status == 'REJECTED') {
                                      statusColor = Colors.red;
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4)),
                                        ],
                                        border: Border.all(color: const Color(0xFFF1F5F9)),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Stack(
                                          children: [
                                            // Left indicator line
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              bottom: 0,
                                              width: 5,
                                              child: Container(color: statusColor),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFEEF2FF),
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        child: const Icon(Icons.picture_as_pdf, color: Color(0xFF6366F1), size: 24),
                                                      ),
                                                      const SizedBox(width: 14),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    title,
                                                                    style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.bold, height: 1.3),
                                                                    maxLines: 2,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 6),
                                                                if (isAdmin)
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                    decoration: BoxDecoration(
                                                                      color: statusColor.withOpacity(0.08),
                                                                      borderRadius: BorderRadius.circular(20),
                                                                      border: Border.all(color: statusColor.withOpacity(0.2)),
                                                                    ),
                                                                    child: Text(
                                                                      status == 'PENDING_APPROVAL' ? 'Pending' : status,
                                                                      style: GoogleFonts.poppins(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 4),
                                                            if (examName != null)
                                                              Text(
                                                                examName,
                                                                style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF8FAFC),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(color: const Color(0xFFF1F5F9)),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.class_outlined, size: 12, color: Color(0xFF64748B)),
                                                            const SizedBox(width: 4),
                                                            Text(className, style: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold)),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF8FAFC),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(color: const Color(0xFFF1F5F9)),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.book_outlined, size: 12, color: Color(0xFF64748B)),
                                                            const SizedBox(width: 4),
                                                            Text(subject, style: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton.icon(
                                                          onPressed: () {
                                                            if (fileUrl != null && fileUrl.isNotEmpty) {
                                                              _launchUrl(fileUrl);
                                                            } else {
                                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paper link is missing.')));
                                                            }
                                                          },
                                                          icon: const Icon(Icons.description_outlined, size: 14),
                                                          label: const Text('View Paper', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                          style: OutlinedButton.styleFrom(
                                                            foregroundColor: const Color(0xFF1E293B),
                                                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                          ),
                                                        ),
                                                      ),
                                                      if (answerKeyUrl != null && answerKeyUrl.isNotEmpty) ...[
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: OutlinedButton.icon(
                                                            onPressed: () => _launchUrl(answerKeyUrl),
                                                            icon: const Icon(Icons.key, size: 14),
                                                            label: const Text('PDF Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                            style: OutlinedButton.styleFrom(
                                                              foregroundColor: const Color(0xFF10B981),
                                                              side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.3)),
                                                              backgroundColor: const Color(0xFF10B981).withOpacity(0.04),
                                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                            ),
                                                          ),
                                                        ),
                                                      ] else if (answerKey != null && answerKey.isNotEmpty) ...[
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: OutlinedButton.icon(
                                                            onPressed: () => _showAnswerKeyDialog(title, answerKey),
                                                            icon: const Icon(Icons.key, size: 14),
                                                            label: const Text('View Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                            style: OutlinedButton.styleFrom(
                                                              foregroundColor: const Color(0xFF10B981),
                                                              side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.3)),
                                                              backgroundColor: const Color(0xFF10B981).withOpacity(0.04),
                                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                      if (_userRole == 'TEACHER') ...[
                                                        const SizedBox(width: 8),
                                                        IconButton(
                                                          icon: const Icon(Icons.edit_note, color: Colors.indigo),
                                                          onPressed: () => _showAnswerKeyUpdateSheet(paper['id'], answerKey, answerKeyUrl),
                                                          style: IconButton.styleFrom(
                                                            backgroundColor: Colors.indigo.withOpacity(0.06),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                            padding: const EdgeInsets.all(12),
                                                          ),
                                                        ),
                                                      ],
                                                      if (isAdmin) ...[
                                                        const SizedBox(width: 8),
                                                        IconButton(
                                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                                          onPressed: () => _deletePaper(paper['id']),
                                                          style: IconButton.styleFrom(
                                                            backgroundColor: Colors.red.withOpacity(0.06),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                            padding: const EdgeInsets.all(12),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  if (isAdmin && (status == 'PENDING_APPROVAL' || status == 'APPROVED' || status == 'REJECTED')) ...[
                                                    const SizedBox(height: 12),
                                                    const Divider(height: 1),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        if (status == 'PENDING_APPROVAL') ...[
                                                          Expanded(
                                                            child: OutlinedButton(
                                                              onPressed: () => _approvePaper(paper['id']),
                                                              style: OutlinedButton.styleFrom(
                                                                foregroundColor: const Color(0xFF10B981),
                                                                side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.5)),
                                                                backgroundColor: const Color(0xFF10B981).withOpacity(0.04),
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                              ),
                                                              child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: OutlinedButton(
                                                              onPressed: () => _rejectPaper(paper['id']),
                                                              style: OutlinedButton.styleFrom(
                                                                foregroundColor: Colors.red,
                                                                side: BorderSide(color: Colors.red.withOpacity(0.5)),
                                                                backgroundColor: Colors.red.withOpacity(0.04),
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                              ),
                                                              child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                                                            ),
                                                          ),
                                                        ],
                                                        if (status == 'APPROVED' || status == 'REJECTED') ...[
                                                          Expanded(
                                                            child: ElevatedButton(
                                                              onPressed: () => _publishPaper(paper['id']),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: const Color(0xFF6366F1),
                                                                foregroundColor: Colors.white,
                                                                elevation: 0,
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                              ),
                                                              child: const Text('Publish Paper', style: TextStyle(fontWeight: FontWeight.bold)),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: (_userRole == 'ADMIN' || _userRole == 'SUPER_ADMIN')
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadQuestionPaperScreen()),
                );
                if (result == true) {
                  _fetchPapers();
                }
              },
              backgroundColor: const Color(0xFF6366F1),
              icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
              label: Text('Upload Paper', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            )
          : null,
    );
  }
}
