import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import 'subject_details_screen.dart';
import 'add_subject_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';

  List<dynamic> _subjects = [];
  List<dynamic> _classes = [];
  List<dynamic> _teachers = [];

  Map<String, List<dynamic>> _groupedSubjects = {};

  final List<List<Color>> _cardGradients = [
    [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Violet
    [const Color(0xFF3B82F6), const Color(0xFF4F46E5)], // Blue-Indigo
    [const Color(0xFF10B981), const Color(0xFF059669)], // Emerald
    [const Color(0xFFF43F5E), const Color(0xFFE11D48)], // Rose
    [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber
    [const Color(0xFF06B6D4), const Color(0xFF0284C7)], // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getSubjects(),
        ApiService.getClasses(),
        ApiService.getTeachers(limit: 5000),
      ]);

      if (mounted) {
        final subRes = results[0];
        final classRes = results[1];
        final teachRes = results[2];

        if (subRes['success'] == true) {
          _subjects = subRes['data'] ?? [];
        } else {
          _errorMessage = subRes['message'] ?? 'Failed to load subjects';
        }

        if (classRes['success'] == true) {
          _classes = classRes['data'] ?? [];
        }

        if (teachRes['success'] == true) {
          dynamic tData = teachRes['data'];
          if (tData is Map && tData.containsKey('data')) {
            _teachers = tData['data'] ?? [];
          } else if (tData is List) {
            _teachers = tData;
          }
        }

        _groupSubjects();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _groupSubjects() {
    _groupedSubjects.clear();
    for (var sub in _subjects) {
      final key = (sub['name']?.toString().trim() ?? 'Unknown').toUpperCase();
      if (!_groupedSubjects.containsKey(key)) {
        _groupedSubjects[key] = [];
      }
      _groupedSubjects[key]!.add(sub);
    }
  }

  Future<void> _deleteSubject(String id) async {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleting...')));
    final result = await ApiService.deleteSubject(id);
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to delete'), backgroundColor: Colors.red));
      }
    }
  }

  void _deleteSubjectConfirm(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: const Text('Are you sure you want to delete this subject?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSubject(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  int _getSubjectWeight(String subject) {
    final s = subject.toUpperCase();
    if (s.contains('TELUGU')) return 1;
    if (s.contains('HINDI')) return 2;
    if (s.contains('ENGLISH')) return 3;
    if (s.contains('MATH')) return 4;
    if (s.contains('BIOLOGY') || s.contains('SCIENCE')) return 5;
    if (s.contains('PHYSICS')) return 6;
    if (s.contains('CHEMISTRY')) return 7;
    if (s.contains('SOCIAL')) return 8;
    return 99;
  }

  @override
  Widget build(BuildContext context) {
    final keys = _groupedSubjects.keys.toList();
    keys.sort((a, b) {
      int wA = _getSubjectWeight(a);
      int wB = _getSubjectWeight(b);
      if (wA != wB) return wA.compareTo(wB);
      return a.compareTo(b);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      drawer: const AppDrawer(currentRoute: 'subjects'),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              title: Text('Subjects & Curriculum', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
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
            
            _isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : _errorMessage.isNotEmpty
                    ? SliverFillRemaining(child: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red))))
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final subjectName = keys[index];
                              final instances = _groupedSubjects[subjectName]!;
                              final colorIndex = subjectName.codeUnitAt(0) % _cardGradients.length;
                              final colors = _cardGradients[colorIndex];
                              
                              int assignedTeachers = 0;
                              for (var inst in instances) {
                                final cst = inst['classSubjectTeachers'] as List<dynamic>? ?? [];
                                if (cst.isNotEmpty && cst.first['teacher'] != null) {
                                  assignedTeachers++;
                                }
                              }

                              return GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SubjectDetailsScreen(
                                        subjectName: subjectName,
                                        subjectInstances: instances,
                                        allTeachers: _teachers,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _fetchData();
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                                        ),
                                        child: Center(
                                          child: Text(
                                            subjectName.substring(0, subjectName.length >= 2 ? 2 : 1).toUpperCase(),
                                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(subjectName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.class_rounded, size: 14, color: Colors.grey.shade400),
                                                const SizedBox(width: 4),
                                                Text('${instances.length} Classes', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                                const SizedBox(width: 16),
                                                Icon(Icons.person_rounded, size: 14, color: Colors.grey.shade400),
                                                const SizedBox(width: 4),
                                                Text('$assignedTeachers Teachers', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                                        child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6366F1), size: 20),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: keys.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
          boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddSubjectScreen(classes: _classes),
              ),
            );
            if (result == true) {
              _fetchData();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('New Subject', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
