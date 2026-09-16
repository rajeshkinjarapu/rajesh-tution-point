import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'add_student_fee_screen.dart';

class FeeStructureManagementScreen extends StatefulWidget {
  const FeeStructureManagementScreen({super.key});

  @override
  State<FeeStructureManagementScreen> createState() => _FeeStructureManagementScreenState();
}

class _FeeStructureManagementScreenState extends State<FeeStructureManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _allStructures = [];
  List<dynamic> _filteredStructures = [];
  List<dynamic> _classes = [];
  
  String _searchQuery = '';
  String? _selectedClass;
  String? _selectedSection;
  
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  List<dynamic> _studentsList = [];

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getFeeStructures(),
        ApiService.getClasses(),
        ApiService.performGet('/api/students?limit=2000', 'Failed to fetch students'),
      ]);
      
      if (mounted) {
        final structRes = results[0];
        final classRes = results[1];
        final stdRes = results[2];

        if (structRes['success']) {
          final data = structRes['data'] ?? [];
          final studentFees = data.where((s) => s['studentId'] != null || s['student'] != null).toList();
          
          setState(() {
            _allStructures = studentFees;
            _classes = classRes['success'] ? classRes['data'] ?? [] : [];
            _studentsList = stdRes['success'] ? (stdRes['data']?['data'] ?? stdRes['data'] ?? []) : [];
            _applyFilters();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredStructures = _allStructures.where((s) {
        final student = s['student'] ?? {};
        final user = student['user'] ?? {};
        
        // Find full student data from _studentsList to get the class info
        final studentId = s['studentId']?.toString();
        Map<String, dynamic> studentClass = student['class'] ?? {};
        
        if (studentClass.isEmpty && studentId != null && _studentsList.isNotEmpty) {
          final fullStudent = _studentsList.firstWhere((st) => st['id']?.toString() == studentId, orElse: () => null);
          if (fullStudent != null && fullStudent['class'] != null) {
            studentClass = fullStudent['class'];
          }
        }
        
        final name = (user['name'] ?? '').toString().toLowerCase();
        final rollNo = (student['rollNo'] ?? '').toString().toLowerCase();
        final q = _searchQuery.toLowerCase();
        
        final matchSearch = name.contains(q) || rollNo.contains(q);
        
        final matchClass = _selectedClass == null || (studentClass['name'] == _selectedClass);
        final matchSection = _selectedSection == null || (studentClass['section'] == _selectedSection);
        
        return matchSearch && matchClass && matchSection;
      }).toList();
    });
  }

  void _showAddFeeDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddStudentFeeScreen()),
    ).then((result) {
      if (result == true) {
        _fetchData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    
    // Stats calculation
    final totalStudents = _allStructures.length;
    double totalExpected = 0.0;
    for (var s in _allStructures) {
      totalExpected += double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0;
    }

    // Unique classes for dropdown
    final classNames = _classes.map((c) => c['name'].toString()).toSet().toList()..sort();
    List<String> sectionNames = [];
    if (_selectedClass != null) {
      sectionNames = _classes
          .where((c) => c['name'] == _selectedClass)
          .map((c) => c['section'].toString())
          .where((s) => s.isNotEmpty)
          .toSet().toList()..sort();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Fee Structures',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : Column(
              children: [
                // Top Dashboard Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'STUDENTS WITH FEE ADDED',
                              value: totalStudents.toString(),
                              icon: Icons.person_outline_rounded,
                              iconColor: const Color(0xFF3B82F6),
                              bgColor: const Color(0xFFEFF6FF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'TOTAL FEE EXPECTED',
                              value: currencyFormat.format(totalExpected),
                              icon: Icons.currency_rupee_rounded,
                              iconColor: const Color(0xFF10B981),
                              bgColor: const Color(0xFFECFDF5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          onChanged: (val) {
                            _searchQuery = val;
                            _applyFilters();
                          },
                          decoration: InputDecoration(
                            icon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                            hintText: 'Search by student name or ID...',
                            hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
                            border: InputBorder.none,
                          ),
                          style: GoogleFonts.poppins(color: const Color(0xFF1E293B)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Dropdowns
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text('Class', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600)),
                                  value: _selectedClass,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                                  items: [
                                    DropdownMenuItem<String>(value: null, child: Text('All Classes', style: GoogleFonts.poppins(fontSize: 13))),
                                    ...classNames.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedClass = val;
                                      _selectedSection = null;
                                    });
                                    _applyFilters();
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (_selectedClass != null && sectionNames.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: Text('Section', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600)),
                                    value: _selectedSection,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                                    items: [
                                      DropdownMenuItem<String>(value: null, child: Text('All Sections', style: GoogleFonts.poppins(fontSize: 13))),
                                      ...sectionNames.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 13)))),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedSection = val;
                                      });
                                      _applyFilters();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // List
                Expanded(
                  child: _filteredStructures.isEmpty
                      ? Center(
                          child: Text(
                            'No fees configured yet.',
                            style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredStructures.length,
                          itemBuilder: (context, index) {
                            final struct = _filteredStructures[index];
                            final student = struct['student'] ?? {};
                            final user = student['user'] ?? {};
                            final studentName = user['name'] ?? 'Unknown Student';
                            final rollNo = student['rollNo'] ?? 'No ID';
                            final feeName = struct['head'] != null ? struct['head']['name'] : (struct['name'] ?? 'Tuition Fee');
                            final amount = double.tryParse(struct['amount']?.toString() ?? '0') ?? 0.0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFEEF2FF),
                                    radius: 22,
                                    child: Text(
                                      studentName.toString().isNotEmpty ? studentName.toString()[0].toUpperCase() : 'U',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentName,
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1E293B)),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              rollNo,
                                              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                feeName,
                                                style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(amount),
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 8.0),
        child: FloatingActionButton.extended(
          onPressed: _showAddFeeDialog,
          backgroundColor: const Color(0xFF4F46E5),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('Add Student Fee', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color iconColor, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
