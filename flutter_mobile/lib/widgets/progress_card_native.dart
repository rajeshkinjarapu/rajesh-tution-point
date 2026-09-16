import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressCardNative extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> settings;

  const ProgressCardNative({
    Key? key,
    required this.data,
    required this.settings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String studentName = data['studentName']?.toString() ?? "Student Name";
    final String rollNo = data['rollNo']?.toString() ?? "Roll No";
    final String className = data['className']?.toString() ?? "Class";
    final String section = data['section']?.toString() ?? "Section";
    final String mobile = data['mobile']?.toString() ?? "";
    final String rank = data['rank']?.toString() ?? "";
    final String academicYear = data['academicYear']?.toString() ?? "2026-2027";
    final String location = data['location']?.toString() ?? "School Location";
    final String photo = data['photo']?.toString() ?? "";
    
    final List<dynamic> rawMarks = data['marks'] is List ? data['marks'] : [];
    final List<Map<String, dynamic>> marksList = rawMarks.whereType<Map<String, dynamic>>().toList();
    
    double totalObtained = 0;
    double totalMax = 0;
    
    for (var m in marksList) {
      bool isAB = m['obtained']?.toString().toUpperCase() == 'AB' || m['remarks']?.toString().toUpperCase() == 'AB';
      double obt = isAB ? 0 : (double.tryParse(m['obtained']?.toString() ?? '0') ?? 0);
      double mx = double.tryParse(m['max']?.toString() ?? m['maxMarks']?.toString() ?? '100') ?? 100;
      
      totalObtained += obt;
      totalMax += mx;
    }
    
    if (totalMax == 0) totalMax = 100;
    final double totalPct = (totalObtained / totalMax) * 100;
    final double safeTotalPct = totalPct.isNaN || totalPct.isInfinite ? 0.0 : totalPct;
    final double safeWidthFactor = (safeTotalPct / 100).clamp(0.0, 1.0);

    return Center(
      child: Container(
        width: 794,
        constraints: const BoxConstraints(minHeight: 1123),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF0B1A33), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
          ]
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1A4A7A), width: 3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                      // Top gradient bar
                      Container(
                        height: 10,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0B1A33), Color(0xFF1A4A7A), Color(0xFFF39C12), Color(0xFFD4A017)],
                            stops: [0.0, 0.3, 0.6, 1.0],
                          ),
                        ),
                      ),
                      
                      // Header Section
                      Container(
                        padding: const EdgeInsets.fromLTRB(32, 18, 32, 12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFF39C12), width: 3)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xE6FFFFFF), Colors.white],
                          )
                        ),
                        child: Row(
                          children: [
                            // Logo area
                            Container(
                              width: 100,
                              height: 100,
                              alignment: Alignment.center,
                              child: const Icon(Icons.workspace_premium, size: 80, color: Color(0xFF1A4A7A)), // Placeholder logo
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    settings['schoolName']?.toString() ?? 'Rajesh Tution Point',
                                    style: const TextStyle(
                                      fontFamily: 'Times New Roman',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0B1A33),
                                      letterSpacing: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    settings['schoolSubtitle']?.toString() ?? '(IIT-JEE / NEET Foundation - Olympiads)',
                                    style: const TextStyle(
                                      fontFamily: 'Times New Roman',
                                      fontSize: 16,
                                      color: Color(0xFF1A4A7A),
                                      letterSpacing: 0.8,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    settings['address']?.toString() ?? 'Opp. Hero Showroom, SVL Paradise Campus, Narasannapeta',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: const Color(0xFF5A7A8A),
                                      letterSpacing: 0.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    data['examName']?.toString() ?? 'JEE MAINS MODEL EXAMINATION - 8',
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      color: const Color(0xFF0B1A33),
                                      letterSpacing: 2.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.star, color: Color(0xFFD4A017), size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'RESULT CARD',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFFD4A017),
                                          letterSpacing: 4.0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.star, color: Color(0xFFD4A017), size: 16),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 100), // Spacer right
                          ],
                        ),
                      ),
                      
                      // Decorative line
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('✦', style: TextStyle(fontSize: 18, color: Color(0xFFD4A017))),
                            const SizedBox(width: 14),
                            Container(
                              width: 140,
                              height: 2,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFF39C12), Colors.transparent])
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text('★', style: TextStyle(fontSize: 18, color: Color(0xFFD4A017))),
                            const SizedBox(width: 14),
                            Container(
                              width: 140,
                              height: 2,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFF39C12), Colors.transparent])
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text('✦', style: TextStyle(fontSize: 18, color: Color(0xFFD4A017))),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Student Info Box
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFF39C12), width: 2),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFF39C12).withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))
                          ],
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFFFFF), Color(0xFFFEF8F0)]
                          )
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildInfoRowA4('STUDENT NAME', studentName, Icons.person, false),
                                    _buildInfoRowA4('STUDENT ID', rollNo, Icons.badge, true),
                                    _buildInfoRowA4('CLASS', className, Icons.school, false),
                                    _buildInfoRowA4('SECTION', section, Icons.class_, true),
                                    _buildInfoRowA4('MOBILE', mobile, Icons.phone, false),
                                    _buildInfoRowA4('ACADEMIC YEAR', academicYear, Icons.calendar_today, true),
                                    _buildInfoRowA4('LOCATION', location, Icons.location_on, false),
                                    _buildInfoRowA4('CLASS RANK', rank.isNotEmpty ? '#$rank' : '-', Icons.emoji_events, true),
                                  ],
                                ),
                              ),
                              // Photo Area
                              Container(
                                width: 130,
                                padding: const EdgeInsets.fromLTRB(12, 14, 20, 14),
                                decoration: const BoxDecoration(
                                  border: Border(left: BorderSide(color: Color(0xFFF5EDE4), width: 2)),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFFFEFCF9), Color(0xFFFCF7EF)]
                                  )
                                ),
                                child: Center(
                                  child: Container(
                                    width: 95,
                                    height: 114,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFF39C12), width: 3),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFFF39C12).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))
                                      ]
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: photo.isNotEmpty
                                        ? Image.network(photo, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person, size: 50, color: Colors.grey))
                                        : const Icon(Icons.person, size: 50, color: Colors.grey)
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 18),
                      
                      // Performance Summary Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Row(
                          children: [
                            const Icon(Icons.bar_chart, color: Color(0xFF1A4A7A), size: 22),
                            const SizedBox(width: 12),
                            Text('Performance Summary', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0B1A33))),
                            const Spacer(),
                            Text('Max Marks: ${totalMax.toInt()}', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6A8AAA))),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Marks Table A4 style
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE8E0D8), width: 2),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))
                            ]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Column(
                              children: [
                                // Header
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF0B1A33), Color(0xFF1A4A7A), Color(0xFF0B1A33)]
                                    )
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 3, child: Text('SUBJECT', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                                      Expanded(flex: 2, child: Center(child: Text('MARKS', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)))),
                                      Expanded(flex: 2, child: Center(child: Text('MAX MARKS', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)))),
                                      Expanded(flex: 2, child: Center(child: Text('%', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)))),
                                    ],
                                  ),
                                ),
                                
                                // Rows
                                ...marksList.asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  var m = entry.value;
                                  bool isEven = idx % 2 == 1;
                                  
                                  bool isAB = m['obtained']?.toString().toUpperCase() == 'AB' || m['remarks']?.toString().toUpperCase() == 'AB';
                                  double obt = isAB ? 0 : (double.tryParse(m['obtained']?.toString() ?? '0') ?? 0);
                                  double mx = double.tryParse(m['max']?.toString() ?? m['maxMarks']?.toString() ?? '100') ?? 100;
                                  double pct = (mx > 0 && !isAB) ? (obt/mx)*100 : 0;
                                  
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isEven ? const Color(0xFFFDFCF9) : Colors.white,
                                      border: const Border(top: BorderSide(color: Color(0xFFE8E0D8), width: 1))
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: Row(
                                          children: [
                                            const SizedBox(width: 4),
                                            Container(width: 10, height: 14, decoration: BoxDecoration(color: const Color(0xFF3498DB), borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(right: 10)),
                                            Expanded(child: Text(m['subject']?.toString() ?? 'Unknown', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A3A5A)))),
                                          ],
                                        )),
                                        Expanded(flex: 2, child: Center(child: Text(isAB ? 'AB' : obt.toStringAsFixed(0), style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isAB ? const Color(0xFFE74C3C) : const Color(0xFF0B1A33))))),
                                        Expanded(flex: 2, child: Center(child: Text(mx.toStringAsFixed(0), style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF6A8AAA))))),
                                        Expanded(flex: 2, child: Center(child: Text(isAB ? '0.0%' : '${pct.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A4A7A))))),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                
                                // Total Row
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [Color(0xFFFDF9F4), Color(0xFFFFF3E0)]),
                                    border: Border(
                                      top: BorderSide(color: Color(0xFFF39C12), width: 2.5),
                                      bottom: BorderSide(color: Color(0xFFF39C12), width: 2.5)
                                    )
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 3, child: Row(
                                        children: [
                                          const SizedBox(width: 4),
                                          const Icon(Icons.push_pin, color: Color(0xFFC0392B), size: 18),
                                          const SizedBox(width: 8),
                                          Text('TOTAL', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF0B1A33), letterSpacing: 1.0)),
                                        ],
                                      )),
                                      Expanded(flex: 2, child: Center(child: Text(totalObtained.toStringAsFixed(0), style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w900, color: const Color(0xFFC0392B))))),
                                      Expanded(flex: 2, child: Center(child: Text(totalMax.toStringAsFixed(0), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF6A8AAA))))),
                                      Expanded(flex: 2, child: Center(child: Text('${safeTotalPct.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1A4A7A))))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Progress Bar A4 style
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFF9FBFD)]),
                          border: Border.all(color: const Color(0xFFDCE4ED), width: 1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2F7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFDCE4ED), width: 1)
                              ),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: safeWidthFactor,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF1A4A7A), Color(0xFF3498DB)]),
                                    borderRadius: BorderRadius.circular(20)
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('0', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6A8AAA))),
                                Text('Threshold: 35%', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6A8AAA))),
                                Text(totalMax.toStringAsFixed(0), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6A8AAA))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Footer Signatures
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Container(
                          padding: const EdgeInsets.only(top: 18, bottom: 20),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFFDCE4ED), width: 2, style: BorderStyle.solid)) 
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.receipt_long, size: 16, color: Color(0xFF1A4A7A)),
                                      const SizedBox(width: 6),
                                      Text('TOTAL MARKS: ${totalObtained.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A4A7A), letterSpacing: 0.5)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${safeTotalPct.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 46, fontWeight: FontWeight.w900, color: const Color(0xFFC0392B), height: 1.0, letterSpacing: -1.0)),
                                ],
                              ),
                              Row(
                                children: [
                                  _buildSignatureLineA4('Teacher Signature', Icons.draw),
                                  const SizedBox(width: 40),
                                  _buildSignatureLineA4('Principal Signature', Icons.verified),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      
                      // Bottom bar
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: const Color(0xFF0B1A33),
                        alignment: Alignment.center,
                        child: Text(
                          '★ This is a system-generated result card for ${data['examName']?.toString() ?? 'EXAMINATION'} ★',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFFAABACA), letterSpacing: 0.5),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
  }

  Widget _buildInfoRowA4(String label, String value, IconData icon, bool isEven) {
    return Container(
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFFEFCF9) : Colors.transparent,
        border: const Border(bottom: BorderSide(color: Color(0xFFF5EDE4), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 170,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
            decoration: const BoxDecoration(
              color: Color(0xFFFDF9F4),
              border: Border(right: BorderSide(color: Color(0xFFF5EDE4), width: 1)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: const Color(0xFF6A3A1A)),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF6A3A1A)))),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
              child: Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0B1A33)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSignatureLineA4(String title, IconData icon) {
    return Column(
      children: [
        const SizedBox(height: 50),
        Container(
          width: 140,
          height: 1.5,
          color: const Color(0xFFC8D6E4),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFD4A017)),
            const SizedBox(width: 6),
            Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A3A5A))),
          ],
        )
      ],
    );
  }
}
