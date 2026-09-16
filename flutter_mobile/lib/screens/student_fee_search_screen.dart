import 'package:flutter/material.dart';
import '../widgets/custom_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'record_fee_payment_screen.dart';
import '../widgets/app_drawer.dart';

class StudentFeeSearchScreen extends StatefulWidget {
  const StudentFeeSearchScreen({super.key});

  @override
  State<StudentFeeSearchScreen> createState() => _StudentFeeSearchScreenState();
}

class _StudentFeeSearchScreenState extends State<StudentFeeSearchScreen> {
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

  void _navigateToStudentFeeDetails(Map<String, dynamic> student) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final res = await ApiService.getFeeStatus(student['id']);
    if (!mounted) return;
    Navigator.pop(context);
    if (res['success']) {
      final List<dynamic> data = res['data'] ?? [];
      final List<Map<String, dynamic>> structures = [];
      for (final d in data) {
         final amountDue = (d['amountDue'] ?? 0.0).toDouble();
         if (amountDue > 0) {
            final stRaw = d['feeStructure'] ?? {};
            final st = Map<String, dynamic>.from(stRaw);
            st['amount'] = amountDue; // Override with pending amount
            final feeHead = st['feeHead'] ?? {};
            st['name'] = feeHead['name'] ?? st['name'] ?? 'Fee Component';
            structures.add(st);
         }
      }
      final pendingAmount = data.fold<double>(0.0, (sum, d) => sum + (d['amountDue'] ?? 0.0));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecordFeePaymentScreen(
            student: student,
            pendingAmount: pendingAmount,
            structures: structures,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to load fee details')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentRoute: 'finance'),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Collect Fee',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFC026D3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Compact Gradient Header with Search and Filter
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFC026D3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Compact Search Field
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _fetchStudents(),
                    style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Search by Name or Adm No...',
                      hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Compact Class Dropdown
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedClass,
                      dropdownColor: const Color(0xFF4F46E5),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedClass = val);
                          _fetchStudents();
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Classes', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        ..._classes.map((cls) {
                          return DropdownMenuItem(
                            value: cls['id'].toString(),
                            child: Text(
                              '${cls['name']} - ${cls['section']}',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]
                              ),
                              child: const Icon(Icons.person_search_rounded, size: 64, color: Color(0xFFCBD5E1)),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No students found',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF94A3B8),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final user = student['user'] ?? {};
                          final name = user['name'] ?? 'Unknown';
                          final admissionNo = student['admissionNumber'] ?? 'N/A';
                          final cls = student['class'] != null ? '${student['class']['name']} - ${student['class']['section']}' : 'N/A';
                          final photoUrl = user['photoUrl'];

                          // Dynamic Color
                          final colorIndex = index % avatarGradients.length;
                          final gradient = avatarGradients[colorIndex];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: gradient[0].withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => _navigateToStudentFeeDetails(student),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Avatar with Loading Fix
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [gradient[0].withOpacity(0.2), gradient[1].withOpacity(0.2)]),
                                          shape: BoxShape.circle,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(30),
                                          child: photoUrl != null && photoUrl.toString().isNotEmpty
                                              ? CustomNetworkImage(
                                                  ApiService.getImageUrl(photoUrl.toString()),
                                                  fit: BoxFit.cover,
                                                  headers: const {'ngrok-skip-browser-warning': '69420'},
                                                  errorBuilder: (context, error, stackTrace) => _buildInitials(name, gradient),
                                                )
                                              : _buildInitials(name, gradient),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFF1E293B),
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                _buildTag('Adm: $admissionNo', const Color(0xFF64748B), const Color(0xFFF1F5F9)),
                                                const SizedBox(width: 8),
                                                _buildTag(cls, gradient[0], gradient[0].withOpacity(0.1)),
                                              ],
                                            ),
                                          ],
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

  Widget _buildInitials(String name, List<Color> gradient) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.outfit(
          color: gradient[0],
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

