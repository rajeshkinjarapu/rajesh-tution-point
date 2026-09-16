import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'create_announcement_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole;

  String _activeFilter = 'ALL'; // ALL, TODAY, HIGH
  String _searchQuery = '';

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadUserRole();
    _fetchAnnouncements();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null && mounted) {
      try {
        final userObj = jsonDecode(userStr);
        setState(() {
          _userRole = userObj['role'];
        });
      } catch (e) {
        // ignore
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await ApiService.getAnnouncements();
      if (mounted) {
        if (res['success']) {
          final rawData = res['data'];
          List<dynamic> items = [];
          if (rawData is List) {
            items = rawData;
          } else if (rawData is Map && rawData['items'] != null) {
            items = rawData['items'];
          }
          setState(() {
            _all = items;
            _applyFilters();
            _isLoading = false;
          });
          _animController.forward(from: 0);
        } else {
          setState(() {
            _errorMessage = res['message'] ?? 'Failed to load announcements';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error. Please check internet and retry.';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<dynamic> base = List.from(_all);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (_activeFilter == 'TODAY') {
      base = base.where((a) {
        final d = (a['createdAt'] ?? '').toString();
        return d.startsWith(today);
      }).toList();
    } else if (_activeFilter == 'HIGH') {
      base = base.where((a) => (a['priority'] ?? 'NORMAL') == 'HIGH').toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      base = base.where((a) {
        return (a['title'] ?? '').toString().toLowerCase().contains(q) ||
               (a['content'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    }

    setState(() {
      _filtered = base;
    });
  }

  void _editAnnouncement(dynamic ann) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateAnnouncementScreen(announcementData: ann)),
    );
    if (result == true) {
      _fetchAnnouncements();
    }
  }

  void _deleteAnnouncement(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Announcement', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this announcement?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final res = await ApiService.deleteAnnouncement(id);
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Announcement deleted'), backgroundColor: Colors.green));
        _fetchAnnouncements();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to delete'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await ApiService.markAnnouncementRead(id);
      // Update local state
      setState(() {
        for (var a in _all) {
          if (a['id'] == id) a['hasRead'] = true;
        }
        _applyFilters();
      });
    } catch (_) {}
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr.substring(0, 10);
    }
  }

  Color _priorityColor(String? priority) {
    switch (priority) {
      case 'HIGH': return const Color(0xFFEF4444);
      case 'LOW': return const Color(0xFF94A3B8);
      default: return const Color(0xFF3B82F6);
    }
  }

  List<Color> _cardGradient(int idx) {
    final gradients = [
      [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFFEC4899), const Color(0xFFDB2777)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
    ];
    return gradients[idx % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Announcements', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E2A66), Color(0xFF222854)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchAnnouncements,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeaderStats()),
          SliverToBoxAdapter(child: _buildSearchAndFilters()),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(child: _buildError())
          else if (_filtered.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ann = _filtered[index];
                  return _buildAnnouncementCard(ann, index);
                },
                childCount: _filtered.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      floatingActionButton: (_userRole == 'ADMIN' || _userRole == 'SUPER_ADMIN')
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()),
                  );
                  if (result == true) {
                    _fetchAnnouncements();
                  }
                },
                backgroundColor: const Color(0xFF4F46E5),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text('New', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          : null,
    );
  }

  Widget _buildHeaderStats() {
    final total = _all.length;
    final urgent = _all.where((a) => a['priority'] == 'HIGH').length;
    final unread = _all.where((a) => a['hasRead'] != true).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _buildStatChip(Icons.campaign_outlined, total.toString(), 'Total', const Color(0xFF6366F1)),
          const SizedBox(width: 10),
          _buildStatChip(Icons.bolt_rounded, urgent.toString(), 'Urgent', const Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          _buildStatChip(Icons.mark_email_unread_rounded, unread.toString(), 'Unread', const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String count, String label, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(count, style: GoogleFonts.outfit(
              color: const Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.w900,
            )),
            Text(label, style: GoogleFonts.poppins(
              color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (v) { setState(() { _searchQuery = v; _applyFilters(); }); },
              decoration: InputDecoration(
                hintText: 'Search announcements…',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              ),
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips
          Row(
            children: [
              _buildFilterChip('ALL', 'All'),
              const SizedBox(width: 8),
              _buildFilterChip('TODAY', 'Today'),
              const SizedBox(width: 8),
              _buildFilterChip('HIGH', '🔴 Urgent'),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isActive = _activeFilter == value;
    return GestureDetector(
      onTap: () { setState(() { _activeFilter = value; _applyFilters(); }); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
              : null,
          color: isActive ? null : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: GoogleFonts.outfit(
          color: isActive ? Colors.white : const Color(0xFF64748B),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        )),
      ),
    );
  }

  Widget _buildAnnouncementCard(dynamic ann, int index) {
    final isPinned = ann['isPinned'] == true;
    final hasRead = ann['hasRead'] == true;
    final priority = ann['priority'] ?? 'NORMAL';
    final status = ann['status'] ?? 'PUBLISHED';
    final gradient = _cardGradient(index);
    final priorityColor = _priorityColor(priority);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () {
          if (!hasRead) _markAsRead(ann['id'].toString());
          _showAnnouncementDetail(ann, gradient);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPinned ? const Color(0xFFFBBF24).withOpacity(0.5) : Colors.transparent,
              width: isPinned ? 1.5 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Colored top strip
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Stack(
                        children: [
                          const Center(child: Icon(Icons.campaign_rounded, color: Colors.white, size: 22)),
                          if (priority == 'HIGH')
                            Positioned(
                              top: 0, right: 0,
                              child: Container(
                                width: 10, height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isPinned) ...[
                                const Icon(Icons.push_pin_rounded, size: 12, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  ann['title'] ?? '',
                                  style: GoogleFonts.outfit(
                                    fontWeight: hasRead ? FontWeight.w600 : FontWeight.w900,
                                    fontSize: 15,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ann['content'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Priority badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  priority == 'HIGH' ? '🔴 Urgent'
                                      : priority == 'LOW' ? '⚪ Low'
                                      : '🔵 Normal',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: priorityColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!hasRead)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('NEW', style: GoogleFonts.outfit(
                                    fontSize: 9, fontWeight: FontWeight.w800,
                                    color: const Color(0xFF6366F1),
                                  )),
                                ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatDate(ann['createdAt']?.toString()),
                                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Unread dot / Admin Menu
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!hasRead)
                          Container(
                            width: 8, height: 8, margin: const EdgeInsets.only(top: 4, left: 6, bottom: 8),
                            decoration: BoxDecoration(
                              color: gradient.first,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (_userRole == 'ADMIN' || _userRole == 'SUPER_ADMIN')
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF94A3B8)),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _editAnnouncement(ann);
                                } else if (val == 'delete') {
                                  _deleteAnnouncement(ann['id'].toString());
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18, color: Color(0xFF1E293B)), SizedBox(width: 8), Text('Edit', style: GoogleFonts.outfit())])),
                                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: GoogleFonts.outfit(color: Colors.red))])),
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
        ),
      ),
    );
  }

  void _showAnnouncementDetail(dynamic ann, List<Color> gradient) {
    final priority = ann['priority'] ?? 'NORMAL';
    final createdByName = ann['createdBy']?['name'] ?? 'School';
    final createdByRole = ann['createdBy']?['role'] ?? '';
    final targetRoles = ann['targetRoles'] ?? '';
    final targetClass = ann['targetClass'];
    final readCount = ann['readCount'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollCtrl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Colored header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Announcement', style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8), fontSize: 12,
                              )),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      priority == 'HIGH' ? '🔴 Urgent'
                                          : priority == 'LOW' ? '⚪ Low'
                                          : '🔵 Normal',
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(ann['title'] ?? '', style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2,
                      )),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meta
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _metaRow(Icons.person_rounded, 'Posted by', '$createdByName ($createdByRole)'),
                            const SizedBox(height: 8),
                            _metaRow(Icons.access_time_rounded, 'Date', _formatDate(ann['createdAt']?.toString())),
                            if (targetRoles.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _metaRow(Icons.people_rounded, 'For', '$targetRoles${targetClass != null ? ' · $targetClass' : ''}'),
                            ],
                            if (readCount > 0) ...[
                              const SizedBox(height: 8),
                              _metaRow(Icons.visibility_rounded, 'Read by', '$readCount people'),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Message', style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: const Color(0xFF475569), letterSpacing: 1,
                      )),
                      const SizedBox(height: 10),
                      Text(ann['content'] ?? '', style: GoogleFonts.poppins(
                        fontSize: 15, color: const Color(0xFF334155),
                        height: 1.7,
                      )),
                      const SizedBox(height: 32),
                      // Mark as Read Button
                      if (ann['hasRead'] != true)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _markAsRead(ann['id'].toString());
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                            label: Text('Mark as Read', style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 16,
                            )),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gradient.first,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                              const SizedBox(width: 8),
                              Text('Read', style: GoogleFonts.outfit(
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.bold, fontSize: 16,
                              )),
                            ],
                          ),
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

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(label, style: GoogleFonts.poppins(
            fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600,
          )),
        ),
        Expanded(
          child: Text(value, style: GoogleFonts.poppins(
            fontSize: 13, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600,
          )),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 20),
            Text(_errorMessage!, textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAnnouncements,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Retry', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_outlined, size: 48, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 20),
            Text('No Announcements', style: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF334155),
            )),
            const SizedBox(height: 8),
            Text('No announcements match your filter.\nPull down to refresh.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}
