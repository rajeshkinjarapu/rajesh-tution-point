import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_drawer.dart';
import 'finance_screen.dart';
import 'exams_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          if (res['success']) {
            final data = res['data'];
            if (data is Map) {
              _notifications = data['notifications'] ?? [];
            } else if (data is List) {
              _notifications = data;
            } else {
              _notifications = [];
            }
          }
        });
      }
    } catch (e) {
      // Offline fallback — load from local cache
      final cached = await NotificationService().getCachedNotifications();
      if (mounted && cached.isNotEmpty) {
        setState(() {
          _notifications = cached.map((n) => {
            'title': n['title'],
            'message': n['body'],
            'isRead': true,
            'createdAt': n['createdAt'],
            'route': n['route'],
            '_isOfflineCached': true,
          }).toList();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final res = await ApiService.markNotificationsRead();
    if (res['success']) {
      setState(() {
        for (var n in _notifications) {
          n['isRead'] = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      drawer: AppDrawer(currentRoute: 'notifications'),
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
        
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notification_add_rounded, color: Color(0xFF818CF8)),
            tooltip: 'Simulate Push Notification',
            onPressed: () {
              NotificationService().showTestNotification(
                'New Homework Added',
                'Mathematics chapter 5 exercises due tomorrow.',
                'homework'
              );
            },
          ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: Color(0xFF10B981)),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded, size: 80, color: const Color(0xFFCBD5E1)),
                      const SizedBox(height: 16),
                      Text(
                        'No New Notifications',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return _buildNotificationCard(notif);
                  },
                ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type?.toUpperCase()) {
      case 'MARKS':
        return Icons.insert_drive_file_rounded;
      case 'ATTENDANCE':
        return Icons.warning_rounded;
      case 'RESULT':
        return Icons.emoji_events_rounded;
      case 'LEAVE':
        return Icons.calendar_month_rounded;
      case 'HOMEWORK':
        return Icons.menu_book_rounded;
      case 'FINANCE':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String? type) {
    switch (type?.toUpperCase()) {
      case 'MARKS':
        return const Color(0xFF3B82F6); // Blue
      case 'ATTENDANCE':
        return const Color(0xFFF59E0B); // Amber
      case 'RESULT':
        return const Color(0xFF10B981); // Emerald
      case 'LEAVE':
        return const Color(0xFFA855F7); // Purple
      case 'HOMEWORK':
        return const Color(0xFF6366F1); // Indigo
      case 'FINANCE':
        return const Color(0xFFEC4899); // Pink
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr.split('T')[0];
    }
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final title = notif['title'] ?? 'Notification';
    final message = notif['message'] ?? '';
    final isRead = notif['isRead'] == true;
    final type = notif['type']?.toString();
    final date = _formatTime(notif['createdAt']?.toString());
    
    final themeColor = _getColorForType(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : themeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isRead ? 0.03 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isRead ? Colors.transparent : themeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (notif['type'] == 'finance') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FinanceScreen()));
            } else if (notif['type'] == 'exams') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExamsScreen()));
            } else {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viewing notification details')));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRead ? const Color(0xFFF1F5F9) : themeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getIconForType(type),
                    color: isRead ? const Color(0xFF94A3B8) : themeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.outfit(
                                color: isRead ? const Color(0xFF334155) : const Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: themeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: GoogleFonts.poppins(
                          color: isRead ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        date,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
}


