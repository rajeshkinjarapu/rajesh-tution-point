import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AttendanceDailyReportScreen extends StatefulWidget {
  const AttendanceDailyReportScreen({super.key});

  @override
  State<AttendanceDailyReportScreen> createState() => _AttendanceDailyReportScreenState();
}

class _AttendanceDailyReportScreenState extends State<AttendanceDailyReportScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  
  List<dynamic> _classSummaries = [];

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final res = await ApiService.getDailyAttendanceSummary(dateStr);
      
      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            List<dynamic> rawData = res['data'] is List ? res['data'] : [];
            
            // Custom Sorting Logic: Nur -> PP1 -> PP2 -> 1st -> 2nd ...
            rawData.sort((a, b) {
              String nameA = (a['className'] ?? '').toString();
              String nameB = (b['className'] ?? '').toString();
              
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
            
            _classSummaries = rawData;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = res['message'] ?? 'Failed to load report';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Color(0xFF1E293B), // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchReport();
    }
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  Widget _buildClassList() {
    if (_classSummaries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No attendance records found for this date.',
            style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
    
    // Sort just before rendering to ensure Nur is first immediately on UI update
    final sortedSummaries = List<dynamic>.from(_classSummaries);
    sortedSummaries.sort((a, b) {
      String nameA = (a['className'] ?? '').toString();
      String nameB = (b['className'] ?? '').toString();
      
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
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))
        ],
        border: Border.all(color: Colors.transparent),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
            borderRadius: BorderRadius.circular(20),
          ),
          columnWidths: const {
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(1.5),
          },
          children: [
            // Table Header
            TableRow(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Text('Class', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Text('Total', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Text('Prs', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Text('Abs', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF43F5E))),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Text('%', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                ),
              ],
            ),
            // Table Body
            ...sortedSummaries.map((c) {
              final className = c['className'] ?? 'Unknown Class';
              final total = c['total'] ?? 0;
              final present = c['present'] ?? 0;
              final absent = c['absent'] ?? 0;
              
              final double percent = total > 0 ? (present / total) * 100 : 0.0;
              
              Color percentColor;
              if (percent >= 85) {
                percentColor = const Color(0xFF10B981);
              } else if (percent >= 50) {
                percentColor = const Color(0xFFF59E0B);
              } else {
                percentColor = const Color(0xFFF43F5E);
              }

              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(
                      className, 
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    child: Text('$total', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    child: Text('$present', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF10B981))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    child: Text('$absent', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFF43F5E))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: percentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${percent.toStringAsFixed(0)}%', 
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: percentColor),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: Text(
          'Daily Report',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
      body: Column(
        children: [
          // Date Picker Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Report Date', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text(
                      '${_getMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.white),
                    label: Text('Change', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _fetchReport, child: const Text('Retry'))
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchReport,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Class-wise Attendance', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                              const SizedBox(height: 12),
                              
                              _buildClassList(),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
