import 'dart:convert';
import '../widgets/custom_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      setState(() {
        _user = jsonDecode(userString);
        _isLoading = false;
      });
    } else {
      final res = await ApiService.getMe();
      if (res['success'] && mounted) {
        setState(() {
          _user = res['data'];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      
      if (pickedFile != null) {
        setState(() => _isLoading = true);
        final bytes = await pickedFile.readAsBytes();
        final base64Str = base64Encode(bytes);
        final ext = pickedFile.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        final dataUri = 'data:$mimeType;base64,$base64Str';
        
        final res = await ApiService.updateProfile({'photoUrl': dataUri});
        
        if (res['success']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated successfully'), backgroundColor: Colors.green));
          await _loadProfile(); // reload profile to show new image
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to update photo'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0D2E),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF818CF8))),
      );
    }

    final name = _user?['name'] ?? 'User Name';
    final email = _user?['email'] ?? '';
    final role = _user?['role'] ?? 'STUDENT';
    final photoUrl = _user?['photoUrl'];
    final studentData = _user?['student'];
    final teacherData = _user?['teacher'];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      drawer: const AppDrawer(currentRoute: 'profile'),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            backgroundColor: const Color(0xFF1E1B4B),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text('My Profile', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF312E81), Color(0xFF1E1B4B), Color(0xFF0F0D2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -40, right: -40,
                    child: Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, left: -30,
                    child: Container(
                      width: 130, height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF818CF8).withOpacity(0.10),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 44),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 112, height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withOpacity(0.5),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 106, height: 106,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                            InkWell(
                              onTap: _pickAndUploadImage,
                              child: ClipOval(
                                child: SizedBox(
                                  width: 98, height: 98,
                                  child: (() {
                                    final avatar = _user?['avatar'] ?? _user?['photo'] ?? _user?['photoUrl'];
                                    if (avatar != null && avatar.toString().isNotEmpty && avatar.toString() != 'null' && avatar.toString() != 'undefined') {
                                      return CustomNetworkImage(
                                        ApiService.getImageUrl(avatar.toString()),
                                        fit: BoxFit.cover,
                                        headers: const {'ngrok-skip-browser-warning': '69420'},
                                        errorBuilder: (c, e, s) => _avatarFallback(name),
                                      );
                                    }
                                    return _avatarFallback(name);
                                  })(),
                                ),
                              ),
                            ),
                            // Camera Icon Badge
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickAndUploadImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            email,
                            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF6366F1)]),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Text(
                            role.replaceAll('_', ' '),
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (role == 'STUDENT' && studentData != null) ...[
                    _statsRow([
                      _StatItem(Icons.class_rounded, 'Class',
                          (studentData['class']?['name'] ?? '?') + '-' + (studentData['class']?['section'] ?? '?'),
                          const Color(0xFF6366F1)),
                      _StatItem(Icons.badge_rounded, 'Roll No', studentData['rollNo']?.toString() ?? 'N/A', const Color(0xFF10B981)),
                      _StatItem(Icons.bloodtype_rounded, 'Blood', studentData['bloodGroup'] ?? 'N/A', const Color(0xFFF43F5E)),
                    ]),
                    const SizedBox(height: 22),
                  ],
                  if (role == 'TEACHER' && teacherData != null) ...[
                    _statsRow([
                      _StatItem(Icons.subject_rounded, 'Subject', teacherData['specialization'] ?? 'N/A', const Color(0xFF6366F1)),
                      _StatItem(Icons.work_history_rounded, 'Exp', (teacherData['experienceYears'] ?? 0).toString() + ' Yrs', const Color(0xFFF59E0B)),
                      _StatItem(Icons.workspace_premium_rounded, 'Qual.', teacherData['qualification'] ?? 'N/A', const Color(0xFF0EA5E9)),
                    ]),
                    const SizedBox(height: 22),
                  ],
                  Text('Settings', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _settingTile(icon: Icons.language_rounded, iconBg: const Color(0xFFEEF2FF), iconColor: const Color(0xFF6366F1), label: 'Language', trailing: 'English'),
                        const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
                        _settingTile(icon: Icons.notifications_active_rounded, iconBg: const Color(0xFFF0FDF4), iconColor: const Color(0xFF10B981), label: 'Push Notifications', trailing: 'Enabled'),
                        const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
                        _settingTile(
                          icon: Icons.lock_rounded, iconBg: const Color(0xFFFFF7ED), iconColor: const Color(0xFFF97316),
                          label: 'Change Password', trailing: 'Update',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _handleLogout,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF4E6A), Color(0xFFE11D48)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text('Sign Out', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: const Color(0xFF6366F1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _statsRow(List<_StatItem> items) {
    return Row(
      children: List.generate(items.length, (i) {
        final chip = items[i];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == items.length - 1 ? 0 : 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: chip.color.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: chip.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(chip.icon, color: chip.color, size: 18),
                ),
                const SizedBox(height: 8),
                Text(chip.value, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(chip.label, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 10)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _settingTile({required IconData icon, required Color iconBg, required Color iconColor, required String label, required String trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w500))),
            Text(trailing, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem(this.icon, this.label, this.value, this.color);
}

