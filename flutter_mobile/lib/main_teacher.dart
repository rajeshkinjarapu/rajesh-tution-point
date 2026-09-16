import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/app_config.dart';
import 'main.dart';
import 'services/notification_service.dart';
import 'services/offline_sync_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Teacher Flavor Configuration
  AppConfig.initialize(AppFlavor.teacher);

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint("Firebase initialization skipped/failed: $e");
    }
  }

  if (!kIsWeb) {
    NotificationService().initialize(navigatorKey);
    OfflineSyncService.initialize();
  }

  runApp(const MyApp());
}
