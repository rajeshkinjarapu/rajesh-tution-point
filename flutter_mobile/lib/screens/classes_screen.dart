import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import 'class_details_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<dynamic> _classes = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  final List<List<Color>> _cardGradients = [
    [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
    [const Color(0xFF10B981), const Color(0xFF059669)],
    [const Color(0xFFF59E0B), const Color(0xFFD97706)],
    [const Color(0xFFEC4899), const Color(0xFFDB2777)],
    [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
    [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
    [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
    [const Color(0xFFF97316), const Color(0xFFEA580C)],
  ];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  int _getClassOrder(String className) {
    final lower = className.toLowerCase();
    if (lower.contains('nur')) return 0;
    if (lower.contains('lkg') || lower.contains('pp1')) return 1;
    if (lower.contains('ukg') || lower.contains('pp2')) return 2;
    if (lower.contains('1st')) return 3;
    if (lower.contains('2nd')) return 4;
    if (lower.contains('3rd')) return 5;
    if (lower.contains('4th')) return 6;
    if (lower.contains('5th')) return 7;
    if (lower.contains('6th')) return 8;
    if (lower.contains('7th')) return 9;
    if (lower.contains('8th')) return 10;
    if (lower.contains('9th')) return 11;
    if (lower.contains('10th')) return 12;
    
    final match = RegExp(r'\d+').firstMatch(lower);
    if (match != null) {
      return 2 + int.parse(match.group(0)!);
    }
    return 99;
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getClasses();
    if (mounted) {
      if (result['success']) {
        setState(() {
          _classes = result['data'] ?? [];
          _classes.sort((a, b) {
            final orderA = _getClassOrder(a['name'] ?? '');
            final orderB = _getClassOrder(b['name'] ?? '');
            if (orderA != orderB) {
              return orderA.compareTo(orderB);
            }
            return (a['section'] ?? '').toString().compareTo((b['section'] ?? '').toString());
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load classes';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredClasses {
    if (_searchQuery.isEmpty) return _classes;
    return _classes.where((c) {
      final name = '${c['name']} ${c['section'] ?? ''}'.toLowerCase();
      final teacher = c['classTeacher']?['user']?['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase()) || teacher.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      drawer: const AppDrawer(currentRoute: 'classes'),
      body: RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: _fetchClasses,
        child: CustomScrollView(
          slivers: [
            // Pinned Main Header
            SliverAppBar(
              pinned: true,
              floating: false,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                'Classes',
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
                  onPressed: _fetchClasses,
                ),
                const SizedBox(width: 4),
              ],
            ),
            
            // Floating Search Box
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(130),
                child: Stack(
                  children: [
                    Container(
                      height: 65,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2E2A66), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Stats row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              _statPill(Icons.school_rounded, '${_classes.length}', 'Total Classes'),
                              const SizedBox(width: 12),
                              _statPill(Icons.people_rounded,
                                  '${_classes.fold<int>(0, (s, c) => s + ((c['_count']?['students'] ?? 0) as int))}',
                                  'Total Students'),
                            ],
                          ),
                        ),
                        // Search
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: TextField(
                              style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search class or teacher...',
                                hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              onChanged: (v) => setState(() => _searchQuery = v),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // List
            _isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))))
                : _errorMessage.isNotEmpty
                    ? SliverFillRemaining(child: _buildError())
                    : _filteredClasses.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 64, color: const Color(0xFFCBD5E1)),
                                  const SizedBox(height: 12),
                                  Text('No classes found', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
                                ],
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildClassCard(_filteredClasses[index], index);
                                },
                                childCount: _filteredClasses.length,
                              ),
                            ),
                          ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(dynamic cls, int index) {
    final String name = cls['name'] ?? 'Unknown';
    final String section = cls['section'] ?? '';
    final String academicYear = cls['academicYear'] ?? 'N/A';
    final String teacherName = cls['classTeacher']?['user']?['name'] ?? 'Not Assigned';
    final int studentsCount = cls['_count']?['students'] ?? 0;
    final String classId = cls['id'] ?? '';
    final List<Color> gradient = _cardGradients[index % _cardGradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ClassDetailsScreen(
                classId: classId,
                className: '$name${section.isNotEmpty ? '-$section' : ''}',
              )),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Gradient avatar
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: gradient[0].withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0] : 'C',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$name${section.isNotEmpty ? ' - $section' : ''}',
                            style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              academicYear,
                              style: GoogleFonts.poppins(color: const Color(0xFF9333EA), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.people_rounded, size: 13, color: gradient[0]),
                          const SizedBox(width: 4),
                          Text(
                            '$studentsCount Students',
                            style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.person_rounded, size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              teacherName,
                              style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFF43F5E)),
          ),
          const SizedBox(height: 16),
          Text(_errorMessage, style: GoogleFonts.poppins(color: const Color(0xFF64748B)), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchClasses,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
