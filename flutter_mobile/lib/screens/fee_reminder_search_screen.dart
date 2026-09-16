import 'package:flutter/material.dart';
import '../widgets/custom_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'fee_reminder_details_screen.dart';

class FeeReminderSearchScreen extends StatefulWidget {
  const FeeReminderSearchScreen({super.key});

  @override
  State<FeeReminderSearchScreen> createState() => _FeeReminderSearchScreenState();
}

class _FeeReminderSearchScreenState extends State<FeeReminderSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _students = [];
  List<dynamic> _classes = [];
  String _selectedClass = 'ALL';

  final List<List<Color>> avatarGradients = [
    [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Indigo to Purple
    [const Color(0xFF10B981), const Color(0xFF34D399)], // Emerald to Teal
    [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], // Amber to Yellow
    [const Color(0xFFEF4444), const Color(0xFFF87171)], // Red to Pink
    [const Color(0xFF3B82F6), const Color(0xFF60A5FA)], // Blue to Sky
  ];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClasses() async {
    final res = await ApiService.getClasses();
    if (mounted && res['success']) {
      setState(() {
        _classes = res['data'] ?? [];
      });
    }
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getStudents(
      classId: _selectedClass == 'ALL' ? null : _selectedClass,
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      limit: 100,
    );
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success']) {
          _students = res['data'] ?? [];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to load students')),
          );
        }
      });
    }
  }

  void _navigateToStudentFeeReminder(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeeReminderDetailsScreen(student: student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Fee Reminders',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                // Class Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedClass,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                      items: [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Classes', style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.w500)),
                        ),
                        ..._classes.map((c) => DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text('${c['name']} ${c['section'] ?? ''}', style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.w500)),
                        ))
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedClass = val);
                          _fetchStudents();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Search Field
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by Name or Roll No...',
                            hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                          ),
                          onSubmitted: (_) => _fetchStudents(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _fetchStudents,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // List Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text('No students found', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final user = student['user'] ?? {};
                          final classInfo = student['class'] ?? {};
                          final name = user['name'] ?? 'Unknown';
                          final rollNo = student['rollNo'] ?? 'N/A';
                          final className = '${classInfo['name'] ?? ''} ${classInfo['section'] ?? ''}'.trim();
                          final photoUrl = user['photoUrl'];

                          final colorIndex = index % avatarGradients.length;
                          final gradientColors = avatarGradients[colorIndex];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _navigateToStudentFeeReminder(student),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: gradientColors),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: (photoUrl != null && photoUrl.isNotEmpty)
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: CustomNetworkImage(
                                                  ApiService.getImageUrl(photoUrl),
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => Text(
                                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                                  child: Text(
                                                    className,
                                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Roll: $rollNo',
                                                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Action
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2FF),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Details',
                                          style: GoogleFonts.poppins(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

