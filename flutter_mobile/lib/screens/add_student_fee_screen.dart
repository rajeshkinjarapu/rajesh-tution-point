import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AddStudentFeeScreen extends StatefulWidget {
  const AddStudentFeeScreen({super.key});

  @override
  State<AddStudentFeeScreen> createState() => _AddStudentFeeScreenState();
}

class _AddStudentFeeScreenState extends State<AddStudentFeeScreen> {
  final _amountController = TextEditingController();
  final _customFeeNameController = TextEditingController();
  
  String _searchQuery = '';
  List<dynamic> _students = [];
  bool _isSearching = false;
  bool _isSaving = false;

  Map<String, dynamic>? _selectedStudent;

  String _selectedCategory = 'Tuition Fee';
  final List<String> _feeCategories = [
    'Tuition Fee',
    'Admission Fee',
    'Application Fee',
    'Transport Fee',
    'Hostel Fee',
    'Custom'
  ];

  void _searchStudents(String query) async {
    setState(() => _searchQuery = query);
    if (query.length < 2) {
      setState(() => _students = []);
      return;
    }
    setState(() => _isSearching = true);
    final res = await ApiService.performGet('/api/students?search=$query&limit=10', 'Failed to search students');
    if (mounted) {
      setState(() {
        _students = res['success'] ? (res['data'] ?? []) : [];
        _isSearching = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a student')));
      return;
    }
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    
    String feeName = _selectedCategory;
    if (_selectedCategory == 'Custom') {
      if (_customFeeNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a custom fee name')));
        return;
      }
      feeName = _customFeeNameController.text.trim();
    }

    setState(() => _isSaving = true);
    final res = await ApiService.performPost(
      '/api/fees/structures',
      {
        'name': feeName,
        'term': 'Annual',
        'amount': amount,
        'studentId': _selectedStudent!['id'],
      },
      'Failed to add fee',
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fee successfully added to student!', style: TextStyle(color: Colors.white)), 
            backgroundColor: Colors.green
          )
        );
        Navigator.pop(context, true); // Return true to signal a refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Add Student Fee',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Student
            _buildSectionTitle('1. Search & Select Student', Icons.person_search_rounded),
            const SizedBox(height: 12),
            
            if (_selectedStudent == null) ...[
              TextField(
                onChanged: _searchStudents,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                  hintText: 'Search student by name or ID...',
                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 12),
              
              if (_isSearching)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF4F46E5))))
              else if (_searchQuery.length >= 2 && _students.isEmpty)
                _buildEmptyState('No students found')
              else if (_students.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _students.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final user = student['user'] ?? {};
                      final name = user['name'] ?? 'Unknown';
                      final rollNo = student['rollNo'] ?? 'No ID';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: Text(
                            name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                        subtitle: Text(rollNo, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                        onTap: () => setState(() {
                          _selectedStudent = student;
                          _searchQuery = '';
                          _students = [];
                        }),
                      );
                    },
                  ),
                ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF4F46E5),
                      child: Text(
                        (_selectedStudent!['user']?['name'] ?? 'U').toString()[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedStudent!['user']?['name'] ?? '',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedStudent!['rollNo'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.red),
                      onPressed: () => setState(() => _selectedStudent = null),
                      tooltip: 'Clear selection',
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // 2. Fee Details
            _buildSectionTitle('2. Fee Details', Icons.payments_rounded),
                const SizedBox(height: 12),
                
                // Fee Category
                Text('Fee Category', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCategory,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                      items: _feeCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: GoogleFonts.poppins(color: const Color(0xFF1E293B))))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
                
                if (_selectedCategory == 'Custom') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _customFeeNameController,
                    decoration: InputDecoration(
                      labelText: 'Custom Fee Name',
                      labelStyle: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Fee Amount Expected (₹)',
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),

                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: const Color(0xFF4F46E5).withOpacity(0.4),
                    ),
                    child: _isSaving 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Add Fee Configuration', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: Color(0xFFCBD5E1), size: 48),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
