import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AnnouncementDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;
  final String userRole;

  const AnnouncementDetailsScreen({
    super.key,
    required this.announcement,
    required this.userRole,
  });

  @override
  State<AnnouncementDetailsScreen> createState() => _AnnouncementDetailsScreenState();
}

class _AnnouncementDetailsScreenState extends State<AnnouncementDetailsScreen> {
  bool _isLoading = false;
  bool _hasRead = false;
  List<dynamic> _readers = [];
  bool _loadingReaders = false;

  @override
  void initState() {
    super.initState();
    _hasRead = widget.announcement['hasRead'] == true;
    if (_isAdmin()) {
      _fetchReaders();
    }
  }

  bool _isAdmin() => widget.userRole == 'ADMIN' || widget.userRole == 'SUPER_ADMIN';

  Future<void> _fetchReaders() async {
    setState(() => _loadingReaders = true);
    final res = await ApiService.getAnnouncementReadStats(widget.announcement['id'].toString());
    if (res['success']) {
      setState(() {
        _readers = res['data']?['readers'] ?? [];
        _loadingReaders = false;
      });
    } else {
      setState(() => _loadingReaders = false);
    }
  }

  Future<void> _markAsRead() async {
    setState(() => _isLoading = true);
    final res = await ApiService.markAnnouncementRead(widget.announcement['id'].toString());
    setState(() => _isLoading = false);
    
    if (res['success']) {
      setState(() => _hasRead = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as read!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Return true to trigger refresh
    }
  }

  void _showReadersList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              Text('Read Status', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: _loadingReaders
                  ? const Center(child: CircularProgressIndicator())
                  : _readers.isEmpty
                    ? const Center(child: Text('No stats available'))
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: _readers.length,
                        itemBuilder: (ctx, i) {
                          final r = _readers[i];
                          final hasRead = r['hasRead'] == true;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: hasRead ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              child: Icon(
                                hasRead ? Icons.check_circle_rounded : Icons.pending_rounded,
                                color: hasRead ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(r['name'] ?? 'User', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(r['role'] ?? '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                            trailing: hasRead
                                ? Text(r['readAt'] != null ? r['readAt'].toString().substring(0, 10) : 'Read', style: const TextStyle(color: Colors.green, fontSize: 12))
                                : const Text('Unread', style: TextStyle(color: Colors.red, fontSize: 12)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.announcement['title'] ?? 'Announcement';
    final content = widget.announcement['content'] ?? '';
    final priority = widget.announcement['priority'] ?? 'NORMAL';
    final createdByName = widget.announcement['createdBy']?['name'] ?? 'School Admin';
    final date = widget.announcement['createdAt'] != null 
        ? widget.announcement['createdAt'].toString().substring(0, 10) 
        : '';

    Color priorityColor = const Color(0xFF3B82F6);
    if (priority == 'HIGH') priorityColor = const Color(0xFFEF4444);
    if (priority == 'LOW') priorityColor = const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text('Announcement Details', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E2A66), Color(0xFF222854)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                priority == 'HIGH' ? '🔴 Urgent' : priority == 'LOW' ? '⚪ Low Priority' : '🔵 Normal',
                style: GoogleFonts.outfit(color: priorityColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            
            // Meta Info
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  child: const Icon(Icons.person, size: 16, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(createdByName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                    Text(date, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                content,
                style: GoogleFonts.poppins(fontSize: 15, height: 1.6, color: const Color(0xFF475569)),
              ),
            ),
            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 16 : 24),
        child: Row(
          children: [
            if (_isAdmin())
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showReadersList,
                  icon: const Icon(Icons.analytics_rounded, color: Colors.white),
                  label: Text('Read Stats', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            if (_isAdmin() && !_hasRead) const SizedBox(width: 12),
            if (!_hasRead)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _markAsRead,
                  icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('READ', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
