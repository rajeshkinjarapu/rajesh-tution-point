import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';

import 'screens/dashboard_screen.dart';
import 'screens/main_layout.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/offline_sync_service.dart';
import 'widgets/offline_banner.dart';
import 'config/app_config.dart';
import 'services/update_service.dart';
import 'services/device_info_service.dart';
import 'screens/student_fee_overview_screen.dart';
import 'screens/student_pay_fee_screen.dart';
import 'screens/student_payment_submission_screen.dart';
import 'screens/student_payment_success_screen.dart';
import 'screens/homework_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  
  // If it's a data-only message (no notification block), we must show it manually
  if (message.notification == null && message.data.isNotEmpty) {
    // Only works if flutter_local_notifications is initialized inside the background isolate,
    // but typically for standard push notifications the backend sends the `notification` payload
    // which Android handles automatically using the default_notification_channel_id we set!
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Global Error Handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("Global Flutter Error: ${details.exception}");
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("Global Platform Error: $error");
    return true; // Prevent app crash
  };

  AppConfig.initialize(AppFlavor.universal);

  try {
    await Supabase.initialize(
      url: 'https://uqwoenpkoinlailxymlb.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVxd29lbnBrb2lubGFpbHh5bWxiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1NTUxOTQsImV4cCI6MjEwNTEzMTE5NH0.kjwv6AhwEZtlFn7X-wi6GsvuyOUaKsppjmFqYsA2GQI',
    );
  } catch (e) {
    debugPrint("Supabase initialization failed: $e");
  }
  
  // Initialize Firebase only on non-web platforms (since web options aren't configured yet)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint("Firebase initialization skipped/failed: $e");
    }
  }
  
  // Initialize Local Notifications only on non-web
  if (!kIsWeb) {
    NotificationService().initialize(navigatorKey);
  }
  // Initialize Offline Sync Service
  if (!kIsWeb) {
    OfflineSyncService.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConfig.current.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConfig.current.primaryColor,
          primary: AppConfig.current.primaryColor,
          secondary: AppConfig.current.secondaryColor,
        ),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      builder: (context, child) {
        return OfflineBanner(child: child!);
      },
      routes: {
        '/student/fees': (context) => const StudentFeeOverviewScreen(),
        '/student/fees/pay': (context) => const StudentPayFeeScreen(),
        '/student/fees/submit': (context) => Container(),
        '/student/fees/success': (context) => const StudentPaymentSuccessScreen(),
        '/student/homework': (context) => const HomeworkScreen(),
      },
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _checkingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    // 1. Validate JSON safely to avoid crashes later
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      try {
        final decoded = jsonDecode(userStr);
        if (decoded is! Map<String, dynamic> || !decoded.containsKey('role')) {
          throw const FormatException('Invalid user schema');
        }
      } catch (e) {
        // Data is corrupted or outdated schema, clear everything
        debugPrint("User data corrupted. Clearing local storage.");
        await prefs.clear();
      }
    }

    final token = await ApiService.getToken();
    if (mounted) {
      UpdateService.checkForUpdate(context);
      if (token != null) {
        DeviceInfoService.updateAppInfo();
      }
      setState(() {
        _isAuthenticated = token != null;
        _checkingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _isAuthenticated ? MainLayout() : const LoginScreen();
  }
}
