import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../services/device_info_service.dart';
import 'main_layout.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════
//  Rajesh Tution Point – DYNAMIC ROLE-BASED LOGIN SCREEN
// ═══════════════════════════════════════════════════════

class _Particle {
  late double x, y, radius, opacity, dx, dy;
  _Particle({required Random rand}) {
    x = rand.nextDouble();
    y = rand.nextDouble();
    radius = rand.nextDouble() * 4 + 2;
    opacity = rand.nextDouble() * 0.28 + 0.05;
    dx = (rand.nextDouble() - 0.5) * 0.0005;
    dy = (rand.nextDouble() - 0.5) * 0.0005;
  }
}

class _AnimatedParticle extends StatefulWidget {
  final _Particle particle;
  const _AnimatedParticle({required this.particle});
  @override
  State<_AnimatedParticle> createState() => _AnimatedParticleState();
}

class _AnimatedParticleState extends State<_AnimatedParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 5000 + Random().nextInt(5000)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final p = widget.particle;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final cx = (p.x + p.dx * t * 1000).clamp(0.0, 1.0);
        final cy = (p.y + p.dy * t * 1000).clamp(0.0, 1.0);
        return Positioned(
          left: cx * size.width - p.radius,
          top: cy * size.height - p.radius,
          child: Container(
            width: p.radius * 2,
            height: p.radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(p.opacity),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────── LoginScreen Widget ───────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _loading = false;
  String? _error;

  final _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();
  bool _canCheckBiometrics = false;
  bool _hasSavedCredentials = false;

  late AnimationController _bgCtrl, _cardCtrl, _pulseCtrl;
  late Animation<double> _bgAnim, _slideAnim, _fadeAnim, _pulseAnim;
  final _particles = <_Particle>[];
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _bgAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut));
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _slideAnim = Tween(begin: 60.0, end: 0.0).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    for (int i = 0; i < 16; i++) {
      _particles.add(_Particle(rand: _rand));
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final savedEmail = await _secureStorage.read(key: 'email');
      final savedPass = await _secureStorage.read(key: 'password');
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck || isSupported;
          _hasSavedCredentials = savedEmail != null && savedPass != null;
        });
      }
    } catch (e) {
      debugPrint('Biometric check failed: $e');
    }
  }

  Future<void> _authenticateBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint or face to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        final email = await _secureStorage.read(key: 'email');
        final pass = await _secureStorage.read(key: 'password');
        if (email != null && pass != null) {
          _emailCtrl.text = email;
          _passCtrl.text = pass;
          _login();
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Error using biometric auth: $e');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await SupabaseService.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (res.user != null) {
        // Fetch profile
        final profile = await SupabaseService.getProfile(res.user!.id);
        if (profile != null) {
          final role = (profile['role'] ?? 'STUDENT').toString().toUpperCase();
          
          if (!AppConfig.isUniversal && !AppConfig.current.allowedRoles.contains(role)) {
            await SupabaseService.logout();
            setState(() {
              _error = 'Role Mismatch: Your account has the "$role" role.';
            });
            return;
          }

          await _secureStorage.write(key: 'email', value: _emailCtrl.text.trim());
          await _secureStorage.write(key: 'password', value: _passCtrl.text);

          final userMap = {
            'id': res.user!.id,
            'email': res.user!.email,
            'name': profile['full_name'] ?? 'User',
            'role': role,
            'student': {'id': res.user!.id}, 
          };
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', jsonEncode(userMap));
          await prefs.setString('accessToken', res.session?.accessToken ?? '');

          DeviceInfoService.updateAppInfo();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Welcome back, ${profile['full_name'] ?? 'User'}!', style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ));

            Navigator.of(context).pushReplacement(PageRouteBuilder(
              pageBuilder: (_, __, ___) => MainLayout(),
              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 500),
            ));
          }
        } else {
          setState(() => _error = 'Profile not found. Please contact admin.');
          await SupabaseService.logout();
        }
      }
    } catch (e) {
      print('LOGIN ERROR: $e');
      if (mounted) setState(() => _error = 'Login failed. Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final config = AppConfig.current;
    final gradColors = config.brandGradient.colors;
    final accentColor = config.primaryColor;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: _bgAnim,
        builder: (_, __) => Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(gradColors[0], gradColors.last, _bgAnim.value)!,
                Color.lerp(gradColors[min(1, gradColors.length - 1)], gradColors[0], _bgAnim.value)!,
                Color.lerp(gradColors.last, gradColors[min(1, gradColors.length - 1)], _bgAnim.value)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(children: [
            ..._particles.map((p) => _AnimatedParticle(particle: p)),
            Positioned(
              top: -size.height * 0.12,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              left: -size.width * 0.15,
              child: Container(
                width: size.width * 0.65,
                height: size.width * 0.65,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.vertical),
                  child: IntrinsicHeight(
                    child: Column(children: [
                      const Spacer(),
                      _buildHero(config),
                      const SizedBox(height: 32),
                      _buildCard(config, accentColor),
                      const Spacer(flex: 2),
                      _buildFooter(),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Hero Section ──────────────────────────────────────────────────────────
  Widget _buildHero(AppConfig config) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Column(children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
          child: Image.asset(
            'assets/images/logo.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(config.roleIcon, size: 75, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          config.appName.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
            shadows: [Shadow(color: Colors.black.withOpacity(0.35), offset: const Offset(0, 3), blurRadius: 10)],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            'EXCELLENCE IN EDUCATION',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ]),
    );
  }

  // ── Login Card ────────────────────────────────────────────────────────────
  Widget _buildCard(AppConfig config, Color accentColor) {
    return AnimatedBuilder(
      animation: _cardCtrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: Opacity(opacity: _fadeAnim.value, child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.17), blurRadius: 40, offset: const Offset(0, 16))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    // Header
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                        child: Icon(config.roleIcon, color: accentColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            config.welcomeTitle,
                            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            config.welcomeSubtitle,
                            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 18),
                    // Accent divider
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [accentColor.withOpacity(0.8), accentColor.withOpacity(0.08)]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Error Banner
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: _error != null
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_rounded, color: Color(0xFFEF4444), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: GoogleFonts.poppins(color: const Color(0xFF991B1B), fontSize: 12.5, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _error = null),
                                  child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                                ),
                              ]),
                            )
                          : const SizedBox.shrink(),
                    ),
                    // ID / Username / Roll No Field
                    _field(
                      ctrl: _emailCtrl,
                      label: config.idFieldLabel,
                      hint: config.idFieldHint,
                      icon: config.roleIcon,
                      accent: accentColor,
                      kbType: TextInputType.emailAddress,
                      validate: (v) => (v == null || v.trim().isEmpty) ? 'Please enter ${config.idFieldLabel}' : null,
                    ),
                    const SizedBox(height: 16),
                    // Password
                    _field(
                      ctrl: _passCtrl,
                      label: 'Password',
                      hint: 'Enter your account password',
                      icon: Icons.lock_outline_rounded,
                      accent: accentColor,
                      obscure: !_showPass,
                      suffix: IconButton(
                        icon: Icon(_showPass ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: const Color(0xFF94A3B8), size: 22),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      ),
                      validate: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
                    ),
                    const SizedBox(height: 24),
                    // Button
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 52,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: accentColor.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6))],
                            ),
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Text(
                                        'SIGN IN',
                                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                    ]),
                            ),
                          ),
                        ),
                        if (_canCheckBiometrics && _hasSavedCredentials) ...[
                          const SizedBox(width: 14),
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: accentColor.withOpacity(0.3)),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.fingerprint_rounded, color: accentColor, size: 28),
                              onPressed: _authenticateBiometric,
                              tooltip: 'Login with Biometrics',
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    // SSL note
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.lock_rounded, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Text(
                        'Secure SSL Encrypted Connection',
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF475569), fontWeight: FontWeight.w500),
                      ),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.help_outline_rounded, color: Colors.white, size: 15),
            const SizedBox(width: 7),
            Text(
              'Need help? Contact Tution Office',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Text(
          '© ${DateTime.now().year} Rajesh Tution Point · All Rights Reserved',
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.7)),
        ),
      ]),
    );
  }

  // ── Reusable Field ────────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    required Color accent,
    TextInputType kbType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validate,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: kbType,
      obscureText: obscure,
      style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14.5),
      validator: validate,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12),
        labelStyle: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w500),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 14, right: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: accent, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2)),
        errorStyle: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
