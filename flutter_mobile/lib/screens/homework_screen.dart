import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _homeworkList = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHomework();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHomework() async {
    final result = await ApiService.getHomework();

    if (mounted) {
      if (result['success']) {
        setState(() {
          _homeworkList = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    }
  }

  Color _getDueDateColor(String dateStr) {
    try {
      final dueDate = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = dueDate.difference(now).inDays;

      if (diff < 0) {
        return const Color(0xFFEF4444); // Red
      } else if (diff <= 1) {
        return const Color(0xFFF59E0B); // Amber
      } else {
        return const Color(0xFF10B981); // Emerald
      }
    } catch (_) {
      return const Color(0xFF64748B); // Slate
    }
  }

  String _getDueDateText(String dateStr) {
    try {
      final dueDate = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = dueDate.difference(now).inDays;

      if (diff < 0) {
        return 'Deadline Passed';
      } else if (diff == 0) {
        return 'Submit Today';
      } else if (diff == 1) {
        return 'Submit Tomorrow';
      } else {
        return 'Submit by ${dueDate.day}/${dueDate.month}/${dueDate.year}';
      }
    } catch (_) {
      return 'No deadline';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    final now = DateTime.now();
    int pendingCount = 0;
    int overdueCount = 0;

    for (var hw in _homeworkList) {
      final dueStr = hw['dueDate']?.toString().split('T')[0] ?? '';
      if (dueStr.isNotEmpty) {
        try {
          final dueDate = DateTime.parse(dueStr);
          if (dueDate.difference(now).inDays < 0) {
            overdueCount++;
          } else {
            pendingCount++;
          }
        } catch (_) {
          pendingCount++;
        }
      } else {
        pendingCount++;
      }
    }
    
    final pendingList = _homeworkList.where((hw) {
      final dueStr = hw['dueDate']?.toString().split('T')[0] ?? '';
      if (dueStr.isEmpty) return true;
      try { return DateTime.parse(dueStr).difference(now).inDays >= 0; } catch (_) { return true; }
    }).toList();
    
    final pastList = _homeworkList.where((hw) {
      final dueStr = hw['dueDate']?.toString().split('T')[0] ?? '';
      if (dueStr.isEmpty) return false;
      try { return DateTime.parse(dueStr).difference(now).inDays < 0; } catch (_) { return false; }
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text(
          'My Homework',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _fetchHomework,
                  color: const Color(0xFF4F46E5),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Tab Bar
                      Container(
                        height: 54,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
                          ),
                          labelColor: const Color(0xFF4F46E5),
                          unselectedLabelColor: const Color(0xFF64748B),
                          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Active Tasks'),
                            Tab(text: 'Past Tasks'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      // Top Summary Boxes
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(child: _buildStatCard('Total', _homeworkList.length.toString(), const Color(0xFFFFFFFF), Icons.assignment_rounded, textColor: const Color(0xFF4F46E5))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('Active', pendingList.length.toString(), const Color(0xFFFFFFFF), Icons.pending_actions_rounded, textColor: const Color(0xFFF59E0B))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('Past', pastList.length.toString(), const Color(0xFFFFFFFF), Icons.history_rounded, textColor: const Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tab Views
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            pendingList.isEmpty ? _buildEmptyState('No active homework. You are all caught up!') : _buildList(pendingList),
                            pastList.isEmpty ? _buildEmptyState('No past homework.') : _buildList(pastList),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String val, Color bgColor, IconData icon, {required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          Text(title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildList(List<dynamic> list) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: list.length,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemBuilder: (context, index) {
        return _buildHomeworkCard(list[index]);
      },
    );
  }

  Widget _buildHomeworkCard(dynamic hw) {
    final title = hw['title'] ?? 'Homework Assignment';
    final desc = hw['description'] ?? 'No description provided.';
    final subject = hw['subject']?['name'] ?? 'General';
    final teacherName = hw['teacher']?['user']?['name'] ?? 'Teacher';
    final dueDateStr = hw['dueDate']?.toString().split('T')[0] ?? '';

    final dueColor = dueDateStr.isNotEmpty ? _getDueDateColor(dueDateStr) : const Color(0xFF64748B);
    final dueText = dueDateStr.isNotEmpty ? _getDueDateText(dueDateStr) : 'No deadline';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: dueColor.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: dueColor.withOpacity(0.2), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  child: Icon(Icons.menu_book_rounded, color: dueColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE0E7FF)),
                        ),
                        child: Text(
                          subject.toUpperCase(),
                          style: GoogleFonts.poppins(color: const Color(0xFF4F46E5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 14, color: const Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Assigned by: $teacherName',
                          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: dueColor),
                      const SizedBox(width: 4),
                      Text(
                        dueText,
                        style: GoogleFonts.poppins(color: dueColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSTRUCTIONS',
                      style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      desc,
                      style: GoogleFonts.poppins(color: const Color(0xFF334155), fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: const Icon(Icons.assignment_turned_in_rounded, size: 64, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 24),
          Text(
            'No Homework Found',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Text(
            msg,
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 60, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _fetchHomework();
            },
            child: Text('Try Again', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
