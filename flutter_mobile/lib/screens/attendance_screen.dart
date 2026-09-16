import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _attendanceRecords = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  late TabController _tabController;

  int _totalDays = 0;
  int _presentDays = 0;
  int _absentDays = 0;
  int _lateDays = 0;
  int _excusedDays = 0;
  double _percentage = 0.0;

  DateTime _today = DateTime.now();
  String _todayStatus = 'NOT_MARKED';
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString == null) {
        setState(() {
          _errorMessage = 'User session not found';
          _isLoading = false;
        });
        return;
      }

      final user = jsonDecode(userString);
      final studentId = user['student']?['id'];
      if (studentId == null) {
        setState(() {
          _errorMessage = 'Student profile information not found';
          _isLoading = false;
        });
        return;
      }

      final result = await ApiService.getAttendance(studentId);

      if (mounted) {
        if (result['success']) {
          final List<dynamic> records = result['data'] ?? [];
          setState(() {
            _attendanceRecords = records;
            _calculateSummary(records);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _calculateSummary(List<dynamic> records) {
    _totalDays = records.length;
    _presentDays = 0;
    _absentDays = 0;
    _lateDays = 0;
    _excusedDays = 0;
    _todayStatus = 'NOT_MARKED';

    String todayStr = "${_today.year}-${_today.month.toString().padLeft(2, '0')}-${_today.day.toString().padLeft(2, '0')}";

    for (var r in records) {
      final status = r['status']?.toString().toUpperCase() ?? '';
      if (status == 'PRESENT') _presentDays++;
      else if (status == 'ABSENT') _absentDays++;
      else if (status == 'LATE') _lateDays++;
      else if (status == 'EXCUSED') _excusedDays++;
      else if (status == 'HOLIDAY') {
        // Optional: Count holidays if they exist in records
      }

      final recordDateStr = r['date']?.toString().split('T')[0];
      if (recordDateStr == todayStr) {
        _todayStatus = status;
      }
    }

    final effectivePresent = _presentDays + _lateDays;
    // Don't count holidays in total if we are doing attendance percentage, but here we just use total records marked.
    _percentage = _totalDays > 0 ? (effectivePresent / _totalDays) * 100 : 0.0;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT': return const Color(0xFF10B981);
      case 'ABSENT': return const Color(0xFFEF4444);
      case 'LATE': return const Color(0xFFF59E0B);
      case 'EXCUSED': return const Color(0xFF3B82F6);
      case 'HOLIDAY': return const Color(0xFF8B5CF6); // Purple for holiday
      case 'SUNDAY': return const Color(0xFFF43F5E); // Pinkish red for sunday
      default: return Colors.grey;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE), // Slightly more colorful light background
      drawer: const AppDrawer(currentRoute: 'attendance'),
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
        ),
        title: Text(
          'My Attendance',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF343063)))
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      child: _buildTabBar(),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSummaryTab(),
                          _buildCalendarTab(),
                          _buildHistoryTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        isScrollable: false,
        labelPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          color: const Color(0xFF4F46E5), // Indigo solid color for active tab
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Summary'),
          Tab(text: 'Calendar'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return RefreshIndicator(
      onRefresh: _fetchAttendance,
      color: const Color(0xFF343063),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_todayStatus == 'ABSENT') _buildAbsenceAlert(),
            _buildTodayStatusBanner(),
            const SizedBox(height: 20),
            _buildPercentageCard(),
            const SizedBox(height: 24),
            Text(
              'Overall Stats',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryStatsGrid(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarTab() {
    return RefreshIndicator(
      onRefresh: _fetchAttendance,
      color: const Color(0xFF343063),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Calendar',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            _buildCalendarCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceAlert() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Absent Today!',
                  style: GoogleFonts.outfit(color: const Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Please submit a leave request.',
                  style: GoogleFonts.poppins(color: const Color(0xFFB91C1C), fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/student/leave');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text('Apply Leave', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildTodayStatusBanner() {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    if (_todayStatus == 'PRESENT') {
      bgColor = const Color(0xFFECFDF5);
      textColor = const Color(0xFF047857);
      icon = Icons.how_to_reg_rounded;
      text = "You're Present Today!";
    } else if (_todayStatus == 'ABSENT') {
      bgColor = const Color(0xFFFEF2F2);
      textColor = const Color(0xFFB91C1C);
      icon = Icons.person_off_rounded;
      text = "You're Absent Today!";
    } else if (_todayStatus == 'LATE') {
      bgColor = const Color(0xFFFFFBEB);
      textColor = const Color(0xFFB45309);
      icon = Icons.run_circle_rounded;
      text = "You're Late Today!";
    } else {
      bgColor = const Color(0xFFEEF2FF);
      textColor = const Color(0xFF4F46E5);
      icon = Icons.pending_actions_rounded;
      text = "Attendance not marked yet for today.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          // Wrapped in Expanded to prevent overflow
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B)),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                  });
                },
              ),
              Text(
                '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    int firstWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday
    if (firstWeekday == 7) firstWeekday = 0; // Make Sunday = 0

    final weekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return Column(
      children: [
        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((day) => 
            SizedBox(
              width: 35, 
              child: Center(
                child: Text(day, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13))
              )
            )
          ).toList(),
        ),
        const SizedBox(height: 12),
        // Days Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: daysInMonth + firstWeekday,
          itemBuilder: (context, index) {
            if (index < firstWeekday) {
              return const SizedBox(); // Empty slots before the first day
            }
            
            final day = index - firstWeekday + 1;
            final dateStr = "${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
            
            // Find status for this day
            String? status;
            for (var r in _attendanceRecords) {
              if (r['date']?.toString().split('T')[0] == dateStr) {
                status = r['status']?.toString().toUpperCase();
                break;
              }
            }

            // Check if it's Sunday
            final thisDate = DateTime(_currentMonth.year, _currentMonth.month, day);
            if (status == null && thisDate.weekday == DateTime.sunday) {
              status = 'SUNDAY';
            }

            Color bgColor = Colors.transparent;
            Color textColor = const Color(0xFF475569);
            FontWeight weight = FontWeight.w500;

            if (status != null && status != 'NOT_MARKED') {
              bgColor = _getStatusColor(status).withOpacity(0.15);
              textColor = _getStatusColor(status);
              weight = FontWeight.bold;
            }

            // Highlight today if it's in the current month
            final isToday = _today.year == _currentMonth.year && _today.month == _currentMonth.month && _today.day == day;
            if (isToday && (status == null || status == 'NOT_MARKED')) {
               bgColor = const Color(0xFFF1F5F9);
               textColor = const Color(0xFF0F172A);
               weight = FontWeight.bold;
            }

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: isToday ? Border.all(color: const Color(0xFF3B82F6), width: 1.5) : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: GoogleFonts.poppins(color: textColor, fontWeight: weight, fontSize: 14),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPercentageCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Row(
        children: [
          // Circular Progress Indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: _percentage / 100,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: _percentage >= 75 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${_percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Great job!',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _percentage >= 75
                      ? 'Your attendance is good! Keep it up.'
                      : 'Maintain at least 75% attendance to avoid penalties.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _percentage >= 75 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: [
        _buildStatTile('Total Classes', '$_totalDays', const Color(0xFF6366F1), Icons.calendar_month_rounded, const Color(0xFFEEF2FF)),
        _buildStatTile('Present', '$_presentDays', const Color(0xFF10B981), Icons.check_circle_rounded, const Color(0xFFECFDF5)),
        _buildStatTile('Absent', '$_absentDays', const Color(0xFFEF4444), Icons.cancel_rounded, const Color(0xFFFEF2F2)),
        _buildStatTile('Late', '$_lateDays', const Color(0xFFF59E0B), Icons.watch_later_rounded, const Color(0xFFFFFBEB)),
      ],
    );
  }

  Widget _buildStatTile(String title, String val, Color color, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
              ]
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  val,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    // Generate last 30 days history dynamically
    List<Map<String, dynamic>> recentHistory = [];
    
    for (int i = 0; i < 30; i++) {
      final date = _today.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      String status = 'NOT MARKED';
      String? note;
      
      // Check if it's in original records
      for (var r in _attendanceRecords) {
        if (r['date']?.toString().split('T')[0] == dateStr) {
          status = r['status']?.toString().toUpperCase() ?? 'NOT MARKED';
          note = r['note']?.toString();
          break;
        }
      }

      // If not in records and it's Sunday, mark as Sunday
      if (status == 'NOT MARKED' && date.weekday == DateTime.sunday) {
        status = 'SUNDAY';
        note = 'Weekend Holiday';
      }

      recentHistory.add({
        'date': dateStr,
        'status': status,
        'note': note,
        'displayDate': '${date.day} ${_getMonthName(date.month)}, ${date.year}',
        'dayName': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
      });
    }

    return RefreshIndicator(
      onRefresh: _fetchAttendance,
      color: const Color(0xFF343063),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: recentHistory.length,
        itemBuilder: (context, index) {
          final item = recentHistory[index];
          final dateStr = item['displayDate'];
          final dayName = item['dayName'];
          final status = item['status'];
          final note = item['note'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          dayName,
                          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note,
                        style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12),
                      )
                    ]
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'NOT MARKED' ? const Color(0xFFF1F5F9) : _getStatusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: GoogleFonts.poppins(
                      color: status == 'NOT MARKED' ? const Color(0xFF64748B) : _getStatusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchAttendance();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF343063),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
