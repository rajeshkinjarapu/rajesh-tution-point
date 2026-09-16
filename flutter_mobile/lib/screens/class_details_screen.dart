import 'package:flutter/material.dart';
import '../widgets/custom_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'student_profile_screen.dart';

class ClassDetailsScreen extends StatefulWidget {
  final String classId;
  final String className;
  const ClassDetailsScreen({super.key, required this.classId, required this.className});

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';

  Map<String, dynamic>? _classDetails;
  List<dynamic> _students = [];
  List<dynamic> _subjects = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getClassDetails(widget.classId),
        ApiService.getClassStudents(widget.classId),
        ApiService.getClassSubjects(widget.classId),
      ]);

      final detailsRes = results[0];
      final studentsRes = results[1];
      final subjectsRes = results[2];

      if (detailsRes['success'] && studentsRes['success'] && subjectsRes['success']) {
        setState(() {
          _classDetails = detailsRes['data'];
          _students = studentsRes['data'] ?? [];
          _subjects = subjectsRes['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = detailsRes['message'] ?? studentsRes['message'] ?? subjectsRes['message'] ?? 'Failed to load data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.className,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E2A66), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchAllData,
          ),
          const SizedBox(width: 4),
        ],
        bottom: _isLoading ? null : TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          tabs: [
            Tab(text: 'STUDENTS (${_students.length})'),
            Tab(text: 'SUBJECTS (${_subjects.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(_errorMessage, style: GoogleFonts.poppins(color: Colors.redAccent)),
                      TextButton(onPressed: _fetchAllData, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildInfoBanner()
    );
  }

  Widget _buildInfoBanner() {
    final String academicYear = _classDetails?['academicYear'] ?? 'N/A';
    final String teacherName = _classDetails?['classTeacher']?['user']?['name'] ?? 'Not Assigned';
    final int studentsCount = _students.length;
    final int subjectsCount = _subjects.length;
    return Column(
      children: [
        // Banner with stats
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E2A66), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              _infoPill(Icons.calendar_month_rounded, academicYear, const Color(0xFF818CF8)),
              const SizedBox(width: 10),
              _infoPill(Icons.people_rounded, '$studentsCount Students', const Color(0xFF34D399)),
              const SizedBox(width: 10),
              _infoPill(Icons.menu_book_rounded, '$subjectsCount Subjects', const Color(0xFFFBBF24)),
            ],
          ),
        ),
        // Teacher row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF1E1B4B),
          child: Row(
            children: [
              const Icon(Icons.person_rounded, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text('Class Teacher: ', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
              Text(teacherName, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStudentsTab(),
              _buildSubjectsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoPill(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Flexible(child: Text(text, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }


  Widget _buildStudentsTab() {
    if (_students.isEmpty) {
      return Center(child: Text('No students found.', style: GoogleFonts.poppins(color: Colors.grey)));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final std = _students[index];
        final String name = std['user']?['name'] ?? 'Unknown';
        final String phone = std['user']?['phone'] ?? '';
        final String rollNo = std['rollNo'] ?? 'N/A';
        final String photoUrl = std['user']?['photoUrl'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentProfileScreen(student: std)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: photoUrl.isNotEmpty
                            ? CustomNetworkImage(
                                photoUrl.startsWith('http') ? photoUrl : '${ApiService.baseUrl}$photoUrl',
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Center(child: Text(name[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)))),
                              )
                            : Center(child: Text(name[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Roll: $rollNo',
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (phone.isNotEmpty)
                                Text(phone, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8))),
                            ],
                          )
                        ],
                      ),
                    ),
                    if (phone.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.call, color: Color(0xFF10B981), size: 20),
                        onPressed: () => _makePhoneCall(phone),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectsTab() {
    if (_subjects.isEmpty) {
      return Center(child: Text('No subjects found.', style: GoogleFonts.poppins(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final sub = _subjects[index];
        final String name = sub['name'] ?? 'Unknown';
        final String code = sub['code'] ?? 'N/A';
        
        // Subject might have classSubjectTeachers mapping
        final teachersMap = sub['classSubjectTeachers'] as List<dynamic>?;
        String teacherName = 'No assignment';
        if (teachersMap != null && teachersMap.isNotEmpty) {
          teacherName = teachersMap[0]['teacher']?['user']?['name'] ?? 'No assignment';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.vpn_key_outlined, size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(
                            code,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Assigned To', style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF94A3B8))),
                    const SizedBox(height: 2),
                    Text(
                      teacherName,
                      style: GoogleFonts.poppins(
                        color: teacherName == 'No assignment' ? Colors.redAccent : const Color(0xFF1E293B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

