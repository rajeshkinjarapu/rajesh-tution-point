import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class TeacherHomeworkScreen extends StatefulWidget {
  const TeacherHomeworkScreen({super.key});

  @override
  State<TeacherHomeworkScreen> createState() => _TeacherHomeworkScreenState();
}

class _TeacherHomeworkScreenState extends State<TeacherHomeworkScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Homework Data
  List<dynamic> _homeworkList = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Selectors Data
  List<dynamic> _classes = [];
  List<dynamic> _subjects = [];
  
  // Filters for History Tab
  String? _filterClassId;
  String? _filterSubjectId;

  // Form State
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedClassId;
  String? _selectedSubjectId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String _status = 'ACTIVE';
  
  // Edit State
  String? _editingId;
  bool _isSubmitting = false;
  String? _formError;

  bool _isAdmin = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkRole();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      final user = jsonDecode(userStr);
      final role = user['role'];
      if (mounted) {
        setState(() {
          _isAdmin = role == 'ADMIN' || role == 'SUPER_ADMIN';
        });
      }
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      ApiService.getHomework(),
      ApiService.getClasses(),
      ApiService.getSubjects(),
    ]);

    if (mounted) {
      if (results[0]['success']) {
        _homeworkList = results[0]['data'] ?? [];
      } else {
        _errorMessage = results[0]['message'];
      }

      if (results[1]['success']) {
        _classes = results[1]['data'] ?? [];
      }
      
      if (results[2]['success']) {
        _subjects = results[2]['data'] ?? [];
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshHomeworks() async {
    final result = await ApiService.getHomework();
    if (mounted && result['success']) {
      setState(() {
        _homeworkList = result['data'] ?? [];
      });
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedClassId == null || _selectedSubjectId == null) {
      setState(() => _formError = 'Please fill all required fields');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final payload = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'classId': _selectedClassId,
      'subjectId': _selectedSubjectId,
      'dueDate': _dueDate.toIso8601String(),
      'status': _status,
    };

    Map<String, dynamic> result;
    if (_editingId != null) {
      result = await ApiService.updateHomework(_editingId!, payload);
    } else {
      result = await ApiService.submitHomework(
        payload['classId']!,
        payload['subjectId']!,
        payload['title']!,
        payload['description']!,
        payload['dueDate']!,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingId != null ? 'Homework updated successfully!' : 'Homework posted successfully!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        _resetForm();
        _tabController.animateTo(0);
        _refreshHomeworks();
      } else {
        setState(() => _formError = result['message']);
      }
    }
  }

  void _resetForm() {
    _editingId = null;
    _titleController.clear();
    _descController.clear();
    _selectedClassId = null;
    _selectedSubjectId = null;
    _dueDate = DateTime.now().add(const Duration(days: 1));
    _status = 'ACTIVE';
    _formError = null;
  }

  void _editHomework(dynamic hw) {
    setState(() {
      _editingId = hw['id'];
      _titleController.text = hw['title'] ?? '';
      _descController.text = hw['description'] ?? '';
      _selectedClassId = hw['class']?['id'];
      _selectedSubjectId = hw['subject']?['id'];
      _dueDate = DateTime.parse(hw['dueDate'] ?? DateTime.now().toIso8601String());
      _status = hw['status'] ?? 'ACTIVE';
    });
    _tabController.animateTo(1);
  }

  Future<void> _deleteHomework(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Homework', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this homework?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await ApiService.deleteHomework(id);
      if (result['success']) {
        _refreshHomeworks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted successfully'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Color _getDueColor(String dateStr, String status) {
    if (status == 'CLOSED') return const Color(0xFF64748B);
    try {
      final dueDate = DateTime.parse(dateStr);
      final diff = dueDate.difference(DateTime.now()).inDays;
      if (diff < 0) return const Color(0xFFEF4444); // Red for past deadline
      if (diff <= 1) return const Color(0xFFF59E0B); // Amber for approaching deadline
      return const Color(0xFF10B981); // Green for active/future
    } catch (_) { return const Color(0xFF64748B); }
  }

  String _getDueText(String dateStr, String status) {
    if (status == 'CLOSED') return 'Closed';
    try {
      final dueDate = DateTime.parse(dateStr);
      final diff = dueDate.difference(DateTime.now()).inDays;
      if (diff < 0) return 'Deadline Passed';
      if (diff == 0) return 'Submit Today';
      if (diff == 1) return 'Submit Tomorrow';
      return 'Submit by ${dueDate.day}/${dueDate.month}/${dueDate.year}';
    } catch (_) { return 'No Deadline'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentRoute: 'homework'),
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
        ),
        title: Text(
          'Homework Manager',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: const Color(0xFF222854),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                dividerColor: Colors.transparent,
                onTap: (index) {
                  if (index == 1 && _editingId == null) {
                    _resetForm(); // Clear form when tapping "Assign New"
                  }
                },
                tabs: const [
                  Tab(text: 'My Homeworks'),
                  Tab(text: 'Assign New'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryTab(),
                _buildFormTab(),
              ],
            ),
    );
  }

  Widget _buildHistoryTab() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: GoogleFonts.poppins(color: Colors.redAccent)),
            TextButton(
              onPressed: _fetchInitialData,
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    // Filter List
    var filteredList = _homeworkList;
    if (_filterClassId != null) {
      filteredList = filteredList.where((hw) => hw['class']?['id'] == _filterClassId).toList();
    }
    if (_filterSubjectId != null) {
      filteredList = filteredList.where((hw) => hw['subject']?['id'] == _filterSubjectId).toList();
    }

    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text('All Classes', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8))),
                      value: _filterClassId,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
                      items: [
                        DropdownMenuItem<String>(value: null, child: const Text('All Classes')),
                        ..._classes.map((c) => DropdownMenuItem<String>(
                              value: c['id'],
                              child: Text('${c['name']}-${c['section']}'),
                            ))
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filterClassId = val;
                          _filterSubjectId = null; // reset subject
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text('All Subjects', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8))),
                      value: _filterSubjectId,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
                      items: [
                        DropdownMenuItem<String>(value: null, child: const Text('All Subjects')),
                        ..._subjects
                            .where((s) => _filterClassId == null || s['classId'] == _filterClassId)
                            .map((s) => DropdownMenuItem<String>(
                                  value: s['id'],
                                  child: Text(_filterClassId == null ? '${s['name']} (${s['class']?['name']}-${s['class']?['section']})' : s['name']),
                                ))
                      ],
                      onChanged: (val) => setState(() => _filterSubjectId = val),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshHomeworks,
            color: const Color(0xFF4F46E5),
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 48, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 16),
                        Text('No homework found', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final hw = filteredList[index];
                      final title = hw['title'] ?? 'Untitled';
                      final className = hw['class'] != null ? '${hw['class']['name']}-${hw['class']['section']}' : 'Unknown';
                      final subjectName = hw['subject']?['name'] ?? 'General';
                      final dueDateStr = hw['dueDate'] ?? '';
                      final status = hw['status'] ?? 'ACTIVE';
                      final teacherName = hw['teacher']?['user']?['name'] ?? 'Teacher';

                      final dueColor = _getDueColor(dueDateStr, status);
                      final dueText = _getDueText(dueDateStr, status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: dueColor.withOpacity(0.08), 
                              blurRadius: 24, 
                              offset: const Offset(0, 8),
                            )
                          ],
                          border: Border.all(color: dueColor.withOpacity(0.2), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, dueColor.withOpacity(0.03)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Icon
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [dueColor.withOpacity(0.15), dueColor.withOpacity(0.05)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: dueColor.withOpacity(0.2), width: 1),
                                    ),
                                    child: Icon(Icons.menu_book_rounded, color: dueColor, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E293B),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                className,
                                                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEEF2FF),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFFE0E7FF)),
                                              ),
                                              child: Text(
                                                subjectName,
                                                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          title,
                                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // Teacher Name & Submission Info Row
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline_rounded, size: 14, color: const Color(0xFF64748B)),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Assigned by: $teacherName',
                                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time_rounded, size: 14, color: dueColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              dueText,
                                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: dueColor),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Menu Actions
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8), size: 28),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        _editHomework(hw);
                                      } else if (val == 'delete') {
                                        _deleteHomework(hw['id']);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF4F46E5)),
                                            const SizedBox(width: 12),
                                            Text('Edit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5))),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                            const SizedBox(width: 12),
                                            Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _editingId != null ? 'Edit Homework' : 'New Homework',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                      if (_editingId != null)
                        TextButton.icon(
                          onPressed: () {
                            _resetForm();
                            _tabController.animateTo(0);
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Cancel Edit'),
                        ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 32),
                  
                  if (_formError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_formError!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Form Fields
                  _buildLabel('Assignment Title'),
                  _buildTextField(_titleController, 'Enter title...'),
                  const SizedBox(height: 20),

                  _buildLabel('Instructions / Description'),
                  _buildTextField(_descController, 'Describe the task...', maxLines: 4),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Class'),
                            _buildDropdown(
                              value: _selectedClassId,
                              items: _classes.map((c) => DropdownMenuItem<String>(value: c['id'], child: Text('${c['name']}-${c['section']}'))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedClassId = val;
                                  _selectedSubjectId = null;
                                });
                              },
                              hint: 'Select Class',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Subject'),
                            _buildDropdown(
                              value: _selectedSubjectId,
                              items: _selectedClassId == null 
                                ? [] 
                                : _subjects
                                  .where((s) => s['classId'] == _selectedClassId)
                                  .map((s) => DropdownMenuItem<String>(value: s['id'], child: Text(s['name'])))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedSubjectId = val),
                              hint: _selectedClassId == null ? 'Select Class First' : 'Select Subject',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Submission Deadline'),
                            InkWell(
                              onTap: _selectDueDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                                      style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6366F1)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_editingId != null) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Status'),
                              _buildDropdown(
                                value: _status,
                                items: const [
                                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                                  DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                                ],
                                onChanged: (val) => setState(() => _status = val!),
                                hint: 'Status',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5), // Indigo color for button
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  shadowColor: const Color(0xFF4F46E5).withOpacity(0.5),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        _editingId != null ? 'Update Homework' : 'Publish Homework',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFCBD5E1)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
      ),
      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown({required String? value, required List<DropdownMenuItem<String>> items, required Function(String?) onChanged, required String hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFCBD5E1))),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF94A3B8)),
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
