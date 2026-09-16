import 'package:flutter/material.dart';
import '../widgets/custom_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<dynamic> _classes = [];
  List<dynamic> _students = [];
  
  String? _selectedClassId;
  DateTime _selectedDate = DateTime.now();
  
  bool _loadingClasses = true;
  bool _loadingStudents = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Local attendance status tracking map: studentId -> status (PRESENT / ABSENT / LATE / EXCUSED)
  final Map<String, String> _studentStatusMap = {};
  final Map<String, TextEditingController> _notesControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  @override
  void dispose() {
    _notesControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchClasses() async {
    final result = await ApiService.getClasses();
    if (mounted) {
      if (result['success']) {
        List<dynamic> classList = result['data'] is List ? List.from(result['data']) : [];
        
        // Custom Sorting Logic: Nur -> PP1 -> PP2 -> 1st -> 2nd ...
        classList.sort((a, b) {
          String nameA = (a['name'] ?? '').toString();
          String nameB = (b['name'] ?? '').toString();
          
          int getWeight(String className) {
            final lower = className.toLowerCase();
            if (lower.contains('nur')) return 0;
            if (lower.contains('pp1') || lower.contains('lkg')) return 1;
            if (lower.contains('pp2') || lower.contains('ukg')) return 2;
            
            final match = RegExp(r'\d+').firstMatch(lower);
            if (match != null) {
              return int.parse(match.group(0)!) + 10;
            }
            return 100;
          }
          
          int weightA = getWeight(nameA);
          int weightB = getWeight(nameB);
          
          if (weightA != weightB) {
            return weightA.compareTo(weightB);
          }
          return nameA.compareTo(nameB);
        });

        setState(() {
          _classes = classList;
          _loadingClasses = false;
          if (classList.isNotEmpty) {
            _selectedClassId = classList[0]['id'];
            _fetchStudents();
          }
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _loadingClasses = false;
        });
      }
    }
  }

  Future<void> _fetchStudents() async {
    if (_selectedClassId == null) return;
    setState(() {
      _loadingStudents = true;
      _errorMessage = null;
      _students = [];
      _studentStatusMap.clear();
      _notesControllers.forEach((_, controller) => controller.dispose());
      _notesControllers.clear();
    });

    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    final result = await ApiService.getAttendanceByClass(_selectedClassId!, dateStr);

    if (mounted) {
      if (result['success']) {
        final List<dynamic> studentList = result['data'] ?? [];
        setState(() {
          _students = studentList;
          _loadingStudents = false;
          
          // Pre-populate local status map from fetched records (if already marked)
          for (var s in studentList) {
            final studentId = s['studentId'];
            final status = s['status']?.toString().toUpperCase() ?? 'PRESENT'; // default to PRESENT
            final note = s['attendance']?['note']?.toString() ?? '';

            _studentStatusMap[studentId] = status;
            _notesControllers[studentId] = TextEditingController(text: note);
          }
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _loadingStudents = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchStudents();
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedClassId == null || _students.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> records = _students.map((s) {
      final studentId = s['studentId'];
      return {
        'studentId': studentId,
        'status': _studentStatusMap[studentId] ?? 'PRESENT',
        'note': _notesControllers[studentId]?.text.trim(),
      };
    }).toList();

    final result = await ApiService.submitBulkAttendance(_selectedClassId!, dateStr, records);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance saved successfully!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F7FE), // Match theme
      drawer: const AppDrawer(currentRoute: 'attendance'),
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'Mark Attendance',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFD946EF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _loadingClasses
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : Column(
              children: [
                // Top Filtering Bar (Glass card style)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Class Selector
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select Class', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedClassId,
                                  dropdownColor: Colors.white,
                                  style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w600),
                                  icon: const Icon(Icons.arrow_drop_down_circle_rounded, color: Color(0xFF6366F1), size: 22),
                                  items: _classes.map<DropdownMenuItem<String>>((c) {
                                    return DropdownMenuItem<String>(
                                      value: c['id'],
                                      child: Text('${c['name']}-${c['section']}'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedClassId = value;
                                    });
                                    _fetchStudents();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Date Picker Trigger
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, color: Color(0xFF6366F1), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF6366F1),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                
                // Student list display area
                Expanded(
                  child: _loadingStudents
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                          : _errorMessage != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 40),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Network Error',
                                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Failed to connect to the server. Please check if your backend/ngrok is running.\n\n${_errorMessage!}',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: _fetchStudents,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF6366F1),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(Icons.refresh_rounded, size: 18),
                                          label: Text('Retry', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                          : _students.isEmpty
                              ? Center(
                                  child: Text(
                                    'No students enrolled in this class.',
                                    style: GoogleFonts.poppins(color: const Color(0xFF475569)),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _students.length,
                                  itemBuilder: (context, index) {
                                    final s = _students[index];
                                    final studentId = s['studentId'];
                                    final name = s['name'] ?? 'Student';
                                    final rollNo = s['rollNo'] ?? s['admissionNumber'] ?? '-';
                                    
                                    final rawPic = s['user'] != null ? s['user']['photoUrl'] : s['photoUrl'];
                                    final profilePic = ApiService.getImageUrl(rawPic?.toString());
                                    
                                    final currentStatus = _studentStatusMap[studentId] ?? 'PRESENT';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))
                                        ],
                                        border: Border.all(color: Colors.transparent),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                // Prominent S.No Badge
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                                                    ],
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                
                                                // Student Image or Initial
                                                Container(
                                                  width: 56,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    gradient: profilePic.isEmpty
                                                        ? const LinearGradient(
                                                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                          )
                                                        : null,
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: const Color(0xFFEEF2FF), width: 2.5),
                                                    boxShadow: [
                                                      BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))
                                                    ],
                                                  ),
                                                  child: profilePic.isNotEmpty
                                                      ? ClipOval(
                                                          child: CustomNetworkImage(
                                                            profilePic,
                                                            width: 56,
                                                            height: 56,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) => Center(
                                                              child: Text(
                                                                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                                                style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 20, fontWeight: FontWeight.bold),
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : Center(
                                                          child: Text(
                                                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                ),
                                                const SizedBox(width: 16),
                                                // Student Name & Roll No
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
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFEEF2FF),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(color: const Color(0xFFC7D2FE)),
                                                          ),
                                                          child: Text(
                                                            'ID: $rollNo',
                                                            style: GoogleFonts.poppins(
                                                              color: const Color(0xFF4F46E5),
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          
                                          // Modern Segmented Control Style Status Buttons
                                          Container(
                                            height: 48,
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Row(
                                              children: [
                                                _buildStatusBtn(studentId, 'PRESENT', const Color(0xFF10B981)),
                                                _buildStatusBtn(studentId, 'ABSENT', const Color(0xFFEF4444)),
                                                _buildStatusBtn(studentId, 'LATE', const Color(0xFFF59E0B)),
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

              // Submit Button
                if (_students.isNotEmpty && !_loadingStudents)
                  SafeArea(
                    top: false,
                    bottom: true,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))
                          ]
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          icon: _isSubmitting ? const SizedBox() : const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                          label: _isSubmitting
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Submit Attendance', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                  )
              ],
            ),
    );
  }

  Widget _buildStatusBtn(String studentId, String status, Color color) {
    final isSelected = _studentStatusMap[studentId] == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _studentStatusMap[studentId] = status;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? color : const Color(0xFF64748B),
            ),
            child: Text(status),
          ),
        ),
      ),
    );
  }
}



