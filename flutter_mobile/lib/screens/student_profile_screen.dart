import 'package:flutter/material.dart';
import '../widgets/custom_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'record_fee_payment_screen.dart';
import 'edit_transaction_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  final dynamic student;
  const StudentProfileScreen({super.key, required this.student});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  Map<String, dynamic>? _studentDetails;
  List<dynamic> _feeStructures = [];
  bool _isLoading = true;
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() { _currentIndex = _tabController.index; });
      }
    });
    _initTabs();
    _fetchProfile();
  }

  Future<void> _initTabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      String role = '';
      if (userStr != null) {
        role = jsonDecode(userStr)['role'] ?? '';
      }
      final isTeacher = role == 'TEACHER';
      if (isTeacher != _isTeacher && mounted) {
        setState(() {
          _isTeacher = isTeacher;
          _tabController.dispose();
          _tabController = TabController(length: _isTeacher ? 2 : 3, vsync: this);
          _tabController.addListener(() {
            if (!_tabController.indexIsChanging && mounted) {
              setState(() { _currentIndex = _tabController.index; });
            }
          });
        });
      }
    } catch (e) {
      debugPrint('Error initTabs: $e');
    }
  }

  Future<void> _fetchProfile() async {
    final id = widget.student['id'] ?? widget.student['_id'] ?? widget.student['studentId'];
    if (id == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final studentRes = await ApiService.getStudentById(id.toString()).timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          if (studentRes['success'] == true && studentRes['data'] != null && studentRes['data'] is Map) {
            _studentDetails = Map<String, dynamic>.from(studentRes['data'] as Map);
          } else {
            _studentDetails = widget.student;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching student details: $e');
      if (mounted) {
        setState(() {
          _studentDetails = widget.student;
        });
      }
    }

    try {
      final feeRes = await ApiService.getFeeStructures().timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          if (feeRes != null && feeRes['success'] == true && feeRes['data'] is List) {
            _feeStructures = feeRes['data'] as List<dynamic>;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching fee structures: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _launchUrl(String scheme, String value) async {
    if (value.isEmpty || value == 'N/A') return;
    final clean = value.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse(scheme == 'tel' ? 'tel:$clean' : scheme == 'whatsapp' ? 'https://wa.me/$clean' : 'mailto:$value');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = _studentDetails ?? widget.student;
    final user = s['user'] ?? {};
    final classInfo = s['class'] ?? {};
    final name = user['name'] ?? 'Unknown Student';
    final photoUrl = user['photoUrl'];
    final rollNo = s['rollNo'] ?? 'N/A';
    final admissionNo = s['admissionNo'] ?? 'N/A';
    final className = '${classInfo['name'] ?? ''} ${classInfo['section'] ?? ''}'.trim();

    String primaryPhone = '';
    final phones = [user['phone'], s['fatherPhone'], s['motherPhone'], s['guardianPhone']];
    for (final p in phones) {
      if (p != null && p.toString().isNotEmpty && p.toString() != 'N/A') {
        primaryPhone = p.toString(); break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Student Profile', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
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
          if (!_isTeacher) IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
            ),
            onPressed: () => _showEditProfileSheet(s),
            tooltip: 'Edit Profile',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: Colors.white,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12.5),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12.5),
              tabs: [
                const Tab(height: 38, text: 'PROFILE'),
                const Tab(height: 38, text: 'EXAMS'),
                if (!_isTeacher) const Tab(height: 38, text: 'FEES'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Hero card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Row(
                children: [
                  Container(
                    width: 84, height: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFEEF2FF), width: 4),
                      boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: (photoUrl != null && (photoUrl as String).isNotEmpty)
                          ? CustomNetworkImage(
                              ApiService.getImageUrl(photoUrl as String),
                              fit: BoxFit.cover,
                              headers: const {'ngrok-skip-browser-warning': '69420'},
                              errorBuilder: (c, e, s) => _avatarFallback(name),
                            )
                          : _avatarFallback(name),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6, runSpacing: 4,
                          children: [
                            _badge(className.isNotEmpty ? className : 'No Class', const Color(0xFF10B981)),
                            _badge('Roll: $rollNo', const Color(0xFF3B82F6)),
                            if (admissionNo != 'N/A') _badge('Adm: $admissionNo', const Color(0xFF8B5CF6)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (primaryPhone.isNotEmpty)
                    GestureDetector(
                      onTap: () => _launchUrl('whatsapp', primaryPhone),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.25)),
                        ),
                        child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF16A34A), size: 22),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(s, user),
                _buildExamsTab(s),
                if (!_isTeacher) _buildFeesTab(s),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 2 ? FloatingActionButton.extended(
        heroTag: 'pay_fee_fab',
        onPressed: () async {
          final s2 = _studentDetails ?? widget.student;
          if (s2['id'] == null) return;
          
          showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))));
          final res = await ApiService.getFeeStatus(s2['id']);
          if (!mounted) return;
          Navigator.pop(context);

          if (res['success']) {
            final List<dynamic> data = res['data'] ?? [];
            final List<Map<String, dynamic>> structures = [];
            for (final d in data) {
               final amountDue = (d['amountDue'] ?? 0.0).toDouble();
               if (amountDue > 0) {
                  final stRaw = d['feeStructure'] ?? {};
                  final st = Map<String, dynamic>.from(stRaw);
                  st['amount'] = amountDue; // Overriding with actual pending amount
                  final feeHead = st['feeHead'] ?? {};
                  st['name'] = feeHead['name'] ?? st['name'] ?? 'Fee Component';
                  structures.add(st);
               }
            }
            
            final pendingAmount = data.fold<double>(0.0, (sum, d) => sum + (d['amountDue'] ?? 0.0));

            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecordFeePaymentScreen(
                student: s2, 
                structures: structures,
                pendingAmount: pendingAmount,
              )),
            );
            if (result == true) { setState(() => _isLoading = true); _fetchProfile(); }
          } else {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to load fee details')));
          }
        },
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.credit_card_rounded, color: Colors.white),
        label: Text('Pay Fee', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      )),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }

  // PROFILE TAB
  Widget _buildProfileTab(Map<String, dynamic> s, Map<String, dynamic> user) {
    final dob = s['dob'] != null ? (DateTime.tryParse(s['dob'].toString())?.toLocal().toString().split(' ')[0] ?? 'N/A') : 'N/A';
    final admDate = s['admissionDate'] != null ? (DateTime.tryParse(s['admissionDate'].toString())?.toLocal().toString().split(' ')[0] ?? 'N/A') : 'N/A';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        children: [
          _infoCard('Personal Details', const Color(0xFF6366F1), [
            _infoRow(Icons.cake_rounded, 'Date of Birth', dob, const Color(0xFF6366F1)),
            _infoRow(Icons.person_rounded, 'Gender', s['gender'] ?? 'N/A', const Color(0xFF8B5CF6)),
            _infoRow(Icons.bloodtype_rounded, 'Blood Group', s['bloodGroup'] ?? 'N/A', const Color(0xFFF43F5E)),
            _infoRow(Icons.credit_card_rounded, 'Aadhaar No', s['aadharNo'] ?? 'N/A', const Color(0xFF0EA5E9)),
            _infoRow(Icons.numbers_rounded, 'PEN Number', s['penNumber'] ?? 'N/A', const Color(0xFF14B8A6)),
            _infoRow(Icons.account_balance_rounded, 'Religion', s['religion'] ?? 'N/A', const Color(0xFFF59E0B)),
            _infoRow(Icons.category_rounded, 'Category', s['casteCategory'] ?? 'N/A', const Color(0xFFEC4899)),
          ]),
          const SizedBox(height: 12),
          _infoCard('Contact & Academic', const Color(0xFF10B981), [
            _infoRow(Icons.email_rounded, 'Email', user['email'] ?? 'Not provided', const Color(0xFF10B981)),
            _infoRow(Icons.home_rounded, 'Address', s['address'] ?? 'Not provided', const Color(0xFF6366F1)),
            _infoRow(Icons.event_available_rounded, 'Admission Date', admDate, const Color(0xFF0EA5E9)),
            _infoRow(Icons.receipt_long_rounded, 'RTE Student', (s['isRTE'] == true) ? 'Yes' : 'No', const Color(0xFF8B5CF6)),
          ]),
          const SizedBox(height: 12),
          _infoCard('Family Details', const Color(0xFFF59E0B), [
            _infoRow(Icons.person_rounded, "Father's Name", s['fatherName'] ?? 'N/A', const Color(0xFF6366F1)),
            _infoRow(Icons.phone_rounded, "Father's Phone", s['fatherPhone'] ?? 'N/A', const Color(0xFF10B981),
                onTap: (s['fatherPhone'] as String?)?.isNotEmpty == true ? () => _launchUrl('tel', s['fatherPhone']) : null),
            _infoRow(Icons.person_rounded, "Mother's Name", s['motherName'] ?? 'N/A', const Color(0xFFEC4899)),
            _infoRow(Icons.phone_rounded, "Mother's Phone", s['motherPhone'] ?? 'N/A', const Color(0xFF10B981),
                onTap: (s['motherPhone'] as String?)?.isNotEmpty == true ? () => _launchUrl('tel', s['motherPhone']) : null),
          ]),
        ],
      ),
    );
  }

  Widget _infoCard(String title, Color accentColor, List<Widget> rows) {
    IconData getIconForTitle(String t) {
      if (t.contains('Personal')) return Icons.person_outline_rounded;
      if (t.contains('Contact')) return Icons.contact_phone_outlined;
      if (t.contains('Family')) return Icons.family_restroom_outlined;
      return Icons.info_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(getIconForTitle(title), size: 16, color: accentColor),
                    const SizedBox(width: 6),
                    Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: accentColor, letterSpacing: 0.3)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...rows.asMap().entries.map((e) => Column(children: [
            e.value,
            if (e.key < rows.length - 1) const Divider(height: 1, indent: 56, color: Color(0xFFF8FAFC)),
          ])),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color iconColor, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08), 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withOpacity(0.15)),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.w600, color: onTap != null ? iconColor : const Color(0xFF0F172A))),
          ])),
          if (onTap != null) Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.call_rounded, size: 14, color: iconColor),
          ),
        ]),
      ),
    );
  }

  // EXAMS TAB
  Widget _buildExamsTab(Map<String, dynamic> s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }
    final marks = (s['marks'] as List?) ?? [];
    if (marks.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.assignment_outlined, size: 64, color: Color(0xFFCBD5E1)),
        const SizedBox(height: 12),
        Text('No exam records', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: marks.length,
      itemBuilder: (context, index) {
        final m = marks[index];
        final obtained = num.tryParse(m['marksObtained']?.toString() ?? '0') ?? 0;
        final max = num.tryParse(m['maxMarks']?.toString() ?? '100') ?? 100;
        final pct = max > 0 ? (obtained / max).clamp(0.0, 1.0) : 0.0;
        final color = pct >= 0.6 ? const Color(0xFF10B981) : pct >= 0.35 ? const Color(0xFFF59E0B) : const Color(0xFFF43F5E);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
          child: Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Icon(Icons.assignment_turned_in_rounded, color: color, size: 22))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m['subject']?['name'] ?? 'Subject', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              Text(m['exam']?['name'] ?? 'Exam', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct.toDouble(), minHeight: 5, backgroundColor: const Color(0xFFE2E8F0), valueColor: AlwaysStoppedAnimation<Color>(color))),
            ])),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${obtained.toStringAsFixed(0)}/${max.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
              Text('${(pct * 100).toStringAsFixed(0)}%', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF94A3B8))),
            ]),
          ]),
        );
      },
    );
  }

  // FEES TAB
  Widget _buildFeesTab(Map<String, dynamic> s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }
    final studentId = s['id'] ?? '';
    final classId = s['classId'] ?? '';
    final applicable = _feeStructures.where((st) => st['studentId'] == studentId || st['classId'] == classId).toList();
    final payments = (s['feePayments'] as List?) ?? [];
    final discounts = (s['feeDiscounts'] as List?) ?? [];

    double totalFee = 0, totalPaid = 0;
    for (final st in applicable) {
      double amt = (st['amount'] ?? 0.0).toDouble();
      double disc = 0;
      for (final d in discounts) { if (d['feeStructureId'] == st['id']) disc = (d['amount'] ?? 0.0).toDouble(); }
      totalFee += (amt - disc).clamp(0, double.infinity);
    }
    for (final p in payments) { totalPaid += (p['amountPaid'] ?? 0.0).toDouble(); }
    final totalPending = (totalFee - totalPaid).clamp(0, double.infinity);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _feeSumCard('Total Fee', '₹${totalFee.toStringAsFixed(0)}', const Color(0xFF6366F1), Icons.account_balance_wallet_rounded),
          const SizedBox(width: 8),
          _feeSumCard('Paid', '₹${totalPaid.toStringAsFixed(0)}', const Color(0xFF10B981), Icons.check_circle_rounded),
          const SizedBox(width: 8),
          _feeSumCard('Pending', '₹${totalPending.toStringAsFixed(0)}', totalPending > 0 ? const Color(0xFFF43F5E) : const Color(0xFF94A3B8), Icons.pending_rounded),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Text('Fee Ledger', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          const Spacer(),
          Text('${applicable.length} items', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        if (applicable.isEmpty) _emptyCard('No fee structures mapped.') else ...applicable.map((st) => _buildLedgerCard(st, studentId, payments, discounts)),
        const SizedBox(height: 20),
        Row(children: [
          Text('Transactions', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          const Spacer(),
          Text('${payments.length} records', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        if (payments.isEmpty) _emptyCard('No transactions yet.') else ...payments.map((t) => _buildTxCard(t, studentId)),
      ]),
    );
  }

  Widget _feeSumCard(String label, String value, Color color, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 4)]),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 10),
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
      ]),
    ));
  }

  Widget _buildLedgerCard(dynamic st, String studentId, List payments, List discounts) {
    double total = (st['amount'] ?? 0.0).toDouble();
    double disc = 0;
    for (final d in discounts) { if (d['feeStructureId'] == st['id']) disc = (d['amount'] ?? 0.0).toDouble(); }
    double effective = (total - disc).clamp(0, double.infinity);
    double paid = 0;
    for (final p in payments) { if (p['feeStructureId'] == st['id']) paid += (p['amountPaid'] ?? 0.0).toDouble(); }
    double pending = (effective - paid).clamp(0, double.infinity);
    double pct = effective > 0 ? (paid / effective).clamp(0.0, 1.0) : 1.0;
    final color = pct >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(st['name'] ?? 'Fee', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)))),
            if (disc > 0) Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${total.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 11, decoration: TextDecoration.lineThrough, color: const Color(0xFF94A3B8))),
              Text('₹${effective.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ]) else Text('₹${effective.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _showDiscountSheet(studentId, st['id'] ?? '', st['name'] ?? 'Fee', disc),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.discount_rounded, size: 16, color: Color(0xFFF97316)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: pct, minHeight: 7, backgroundColor: const Color(0xFFE2E8F0), valueColor: AlwaysStoppedAnimation<Color>(color))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('Paid ₹${paid.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
            ]),
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: pending > 0 ? const Color(0xFFF43F5E) : const Color(0xFFCBD5E1), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('Pending ₹${pending.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: pending > 0 ? const Color(0xFFF43F5E) : const Color(0xFF94A3B8))),
            ]),
          ]),
          if (disc > 0) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              const Icon(Icons.discount_rounded, size: 12, color: Color(0xFFF97316)),
              const SizedBox(width: 4),
              Text('Discount: ₹${disc.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFF97316), fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildTxCard(dynamic t, String studentId) {
    final amount = t['amountPaid']?.toString() ?? '0';
    final method = t['method'] ?? t['paymentMethod'] ?? 'CASH';
    final dateRaw = t['paymentDate'] ?? t['date'] ?? t['createdAt'];
    final date = dateRaw != null ? (DateTime.tryParse(dateRaw.toString())?.toLocal().toString().split(' ')[0] ?? 'N/A') : 'N/A';
    final receipt = t['receiptNo'] ?? '';
    final feeName = t['feeStructure']?['name'] ?? 'Fee Payment';
    final methodColor = method == 'UPI' ? const Color(0xFF8B5CF6) : method == 'CHEQUE' ? const Color(0xFF0EA5E9) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: methodColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Icon(Icons.receipt_rounded, color: methodColor, size: 20))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(feeName, style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Text(date, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8))),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: methodColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                  child: Text(method, style: GoogleFonts.poppins(fontSize: 9.5, color: methodColor, fontWeight: FontWeight.bold))),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹$amount', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
            if (receipt.isNotEmpty) Text(receipt, style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF94A3B8))),
          ]),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFFCBD5E1), size: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'edit') _showEditTxSheet(t);
              if (val == 'delete') _confirmDeleteTx(t['id']?.toString());
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF6366F1)), const SizedBox(width: 8), Text('Edit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600))])),
              PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_rounded, size: 16, color: Color(0xFFF43F5E)), const SizedBox(width: 8), Text('Delete', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFF43F5E)))])),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Center(child: Text(msg, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)))),
    );
  }

  // EDIT PROFILE SHEET
  void _showEditProfileSheet(Map<String, dynamic> s) {
    final dobC = TextEditingController(text: s['dob']?.toString().split('T')[0] ?? '');
    final genderC = TextEditingController(text: s['gender'] ?? '');
    final bloodC = TextEditingController(text: s['bloodGroup'] ?? '');
    final fatherNameC = TextEditingController(text: s['fatherName'] ?? '');
    final motherNameC = TextEditingController(text: s['motherName'] ?? '');
    final fatherPhoneC = TextEditingController(text: s['fatherPhone'] ?? '');
    final motherPhoneC = TextEditingController(text: s['motherPhone'] ?? '');
    final addressC = TextEditingController(text: s['address'] ?? '');
    final religionC = TextEditingController(text: s['religion'] ?? '');
    final categoryC = TextEditingController(text: s['casteCategory'] ?? '');
    final aadharC = TextEditingController(text: s['aadharNo'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(builder: (ctx, setSS) => DraggableScrollableSheet(
          initialChildSize: 0.92, minChildSize: 0.6, maxChildSize: 0.97,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          ),
                          child: const Icon(Icons.edit_document, color: Colors.white, size: 20)
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Text('Edit Student Profile', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)))),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx), 
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 16),
                          )
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              Expanded(child: SingleChildScrollView(
                controller: sc,
                padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
                child: Column(children: [
                  _editSection('Personal', [
                    _editField('Date of Birth', dobC, hint: 'YYYY-MM-DD', icon: Icons.cake_rounded),
                    _editField('Gender', genderC, hint: 'MALE / FEMALE', icon: Icons.person_rounded),
                    _editField('Blood Group', bloodC, hint: 'A+, B-, O+...', icon: Icons.bloodtype_rounded),
                    _editField('Aadhaar No', aadharC, icon: Icons.credit_card_rounded, keyboardType: TextInputType.number),
                    _editField('Religion', religionC, icon: Icons.account_balance_rounded),
                    _editField('Category', categoryC, icon: Icons.category_rounded),
                    _editField('Address', addressC, icon: Icons.home_rounded, maxLines: 2),
                  ]),
                  const SizedBox(height: 16),
                  _editSection('Family', [
                    _editField("Father's Name", fatherNameC, icon: Icons.person_rounded),
                    _editField("Father's Phone", fatherPhoneC, icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
                    _editField("Mother's Name", motherNameC, icon: Icons.person_rounded),
                    _editField("Mother's Phone", motherPhoneC, icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
                  ]),
                ]),
              )),
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                child: GestureDetector(
                  onTap: isSaving ? null : () async {
                    setSS(() => isSaving = true);
                    final data = <String, dynamic>{};
                    if (dobC.text.isNotEmpty) data['dob'] = dobC.text;
                    if (genderC.text.isNotEmpty) data['gender'] = genderC.text.toUpperCase();
                    if (bloodC.text.isNotEmpty) data['bloodGroup'] = bloodC.text;
                    if (fatherNameC.text.isNotEmpty) data['fatherName'] = fatherNameC.text;
                    if (motherNameC.text.isNotEmpty) data['motherName'] = motherNameC.text;
                    if (fatherPhoneC.text.isNotEmpty) data['fatherPhone'] = fatherPhoneC.text;
                    if (motherPhoneC.text.isNotEmpty) data['motherPhone'] = motherPhoneC.text;
                    if (addressC.text.isNotEmpty) data['address'] = addressC.text;
                    if (religionC.text.isNotEmpty) data['religion'] = religionC.text;
                    if (categoryC.text.isNotEmpty) data['casteCategory'] = categoryC.text;
                    if (aadharC.text.isNotEmpty) data['aadharNo'] = aadharC.text;
                    final res = await ApiService.updateStudent(s['id'] ?? '', data);
                    setSS(() => isSaving = false);
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(res['success'] ? 'Profile updated!' : (res['message'] ?? 'Failed')),
                        backgroundColor: res['success'] ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      ));
                      if (res['success']) { setState(() => _isLoading = true); _fetchProfile(); }
                    }
                  },
                  child: Container(
                    width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Center(child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text('Save Changes', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
            ]),
          ),
        ));
      },
    );
  }

  Widget _editSection(String label, List<Widget> fields) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 16, 12),
        child: Row(
          children: [
            Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text(label.toUpperCase(), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B), letterSpacing: 0.5)),
          ],
        ),
      ),
      ...fields,
      const SizedBox(height: 16),
    ]);
  }

  Widget _editField(String label, TextEditingController ctrl, {String? hint, IconData? icon, TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl, keyboardType: keyboardType, maxLines: maxLines,
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint, hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFCBD5E1)),
              prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF64748B)) : null,
              filled: true, fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  // DISCOUNT SHEET
  void _showDiscountSheet(String studentId, String feeStructureId, String feeName, double existing) {
    final amountC = TextEditingController(text: existing > 0 ? existing.toStringAsFixed(0) : '');
    final remarksC = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(builder: (ctx, setSS) => SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
              Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.discount_rounded, color: Color(0xFFF97316), size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Apply Discount', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
                  Text(feeName, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                ])),
              ]),
              const SizedBox(height: 20),
              TextField(
                controller: amountC, keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFFF97316)),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '₹ ', prefixStyle: GoogleFonts.outfit(fontSize: 22, color: const Color(0xFFF97316)),
                  hintText: '0', hintStyle: GoogleFonts.outfit(fontSize: 22, color: const Color(0xFFCBD5E1)),
                  filled: true, fillColor: const Color(0xFFFFF7ED),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksC, style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Remark (optional)...', hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFCBD5E1)),
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: isSaving ? null : () async {
                  final amt = double.tryParse(amountC.text);
                  if (amt == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amount'))); return; }
                  setSS(() => isSaving = true);
                  final res = await ApiService.applyFeeDiscount(studentId: studentId, feeStructureId: feeStructureId, discountAmount: amt, remarks: remarksC.text);
                  setSS(() => isSaving = false);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['success'] ? 'Discount ₹$amt applied!' : (res['message'] ?? 'Failed')), backgroundColor: res['success'] ? const Color(0xFF10B981) : const Color(0xFFF43F5E)));
                    if (res['success']) { setState(() => _isLoading = true); _fetchProfile(); }
                  }
                },
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFFF97316).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Center(child: isSaving ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : Text('Apply Discount', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
                ),
              ),
            ]),
          ),
        )));
      },
    );
  }

  // EDIT TRANSACTION SHEET - Moved to separate screen
  void _showEditTxSheet(dynamic t) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTransactionScreen(transaction: t)),
    ).then((updated) {
      if (updated == true && mounted) {
        setState(() => _isLoading = true);
        _fetchProfile();
      }
    });
  }

  void _confirmDeleteTx(String? paymentId) {
    if (paymentId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_rounded, color: Color(0xFFF43F5E), size: 20)),
          const SizedBox(width: 12),
          Text('Delete Transaction?', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text('This cannot be undone. Fee balance will be recalculated.', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ApiService.deleteFeePayment(paymentId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['success'] ? 'Transaction deleted' : (res['message'] ?? 'Failed')), backgroundColor: res['success'] ? const Color(0xFF10B981) : const Color(0xFFF43F5E)));
                if (res['success']) { setState(() => _isLoading = true); _fetchProfile(); }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
