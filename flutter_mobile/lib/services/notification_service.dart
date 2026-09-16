import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';
import '../screens/homework_screen.dart';
import '../screens/announcements_screen.dart';

import '../screens/messages_screen.dart';

/// Cached notification key in SharedPreferences
const String _kCachedNotifications = 'cached_notifications';
const String _kLastNotifShownAt = 'last_notif_shown_at';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? navigatorKey;

  // ─────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────
  Future<void> initialize(GlobalKey<NavigatorState> key) async {
    navigatorKey = key;

    // ── 1. Local Notifications Setup ──
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );

    // ── 2. Create HIGH_IMPORTANCE channel (Android) ──
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'rajeshtution_alerts_v3', // Bumped ID to force recreate channel
      'Rajesh Tution Point Important Alerts',
      description: 'Critical school notifications — attendance, fees, exams.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    await androidImplementation?.createNotificationChannel(channel);
    
    // Explicitly request notification permission for Android 13+
    await androidImplementation?.requestNotificationsPermission();

    // ── 3. FCM Setup ──
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      String? token = await messaging.getToken();
      debugPrint('FCM Token: $token');

      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token Refreshed: $newToken');
      });

      // Foreground FCM → show local banner + cache it
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground FCM received!');
        if (message.notification != null) {
          final title = message.notification!.title;
          final body = message.notification!.body;
          final route = message.data['route'];
          _showHeroBanner(title, body, route);
          _cacheNotification(title, body, route);
        }
      });

      // Background app open
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.data['route'] != null) {
          _navigateToRoute(message.data['route']);
        }
      });
    } catch (e) {
      debugPrint('FCM Init Error (safe to ignore on web/desktop): $e');
    }

    // ── 4. Connectivity listener ──
    // When internet comes back: fetch fresh notifications → cache them
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline) {
        _fetchAndCacheServerNotifications();
      }
    });

    // ── 5. On launch: check connectivity ──
    // Online → fetch fresh + show banners
    // Offline → replay cached banners
    _handleLaunchNotifications();
  }

  // ─────────────────────────────────────────────────────────────
  // LAUNCH: ONLINE → FETCH & CACHE, OFFLINE → REPLAY CACHE
  // ─────────────────────────────────────────────────────────────
  Future<void> _handleLaunchNotifications() async {
    // Small delay so app UI renders first
    await Future.delayed(const Duration(seconds: 2));

    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = !connectivityResults.contains(ConnectivityResult.none);

    if (isOnline) {
      await _fetchAndCacheServerNotifications();
    } else {
      // Offline — replay cached notifications as hero banners
      await _replayCachedNotifications();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FETCH FROM SERVER AND CACHE
  // ─────────────────────────────────────────────────────────────
  Future<void> _fetchAndCacheServerNotifications() async {
    try {
      final res = await ApiService.getNotifications();
      if (res['success'] == true) {
        final dynamic payload = res['data'];
        final List<dynamic> data = (payload is Map && payload.containsKey('notifications'))
            ? (payload['notifications'] ?? [])
            : (payload is List ? payload : []);

        // Take the 5 most recent unread notifications
        final unread = data
            .where((n) => n['isRead'] == false)
            .take(5)
            .map((n) => {
                  'title': n['title'] ?? 'Rajesh Tution Point',
                  'body': n['message'] ?? n['body'] ?? '',
                  'route': n['route'] ?? 'announcements',
                  'createdAt': n['createdAt'] ?? DateTime.now().toIso8601String(),
                })
            .toList();

        await _saveToCache(unread);

        // NOTE: We used to call _showHeroBanner here for unread notifications,
        // but this caused notifications to trigger repeatedly on app launch or network change.
        // Banners should only be triggered directly by FCM, not by fetching history.
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      // If fetch fails (maybe partial internet), just log it. UI will use cache.
      await _replayCachedNotifications();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REPLAY CACHED NOTIFICATIONS AS HERO BANNERS
  // ─────────────────────────────────────────────────────────────
  Future<void> _replayCachedNotifications() async {
    final cached = await _loadFromCache();
    if (cached.isEmpty) {
      // No cache available, just return silently instead of showing an annoying fake notification
      return;
    }

    // Replaying cached notifications as system push notifications is annoying UX.
    // The cache will just be read by the Notifications Screen UI.
    debugPrint('Offline/Error: Cached notifications are ready for UI.');
  }

  // ─────────────────────────────────────────────────────────────
  // SHOW HERO BANNER (MAX IMPORTANCE LOCAL NOTIFICATION)
  // ─────────────────────────────────────────────────────────────
  Future<void> _showHeroBanner(String? title, String? body, String? route) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rajeshtution_alerts_v3',
      'Rajesh Tution Point Important Alerts',
      channelDescription: 'Critical school notifications.',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: false,  // true would lock screen — not needed
      styleInformation: BigTextStyleInformation(body ?? ''),
      ticker: title,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title ?? 'Rajesh Tution Point',
      body ?? '',
      details,
      payload: route,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CACHE HELPERS (SharedPreferences)
  // ─────────────────────────────────────────────────────────────
  Future<void> _cacheNotification(String? title, String? body, String? route) async {
    final existing = await _loadFromCache();
    existing.insert(0, {
      'title': title ?? 'Rajesh Tution Point',
      'body': body ?? '',
      'route': route ?? 'announcements',
      'createdAt': DateTime.now().toIso8601String(),
    });
    // Keep max 10 cached
    final trimmed = existing.take(10).toList();
    await _saveToCache(trimmed);
  }

  Future<void> _saveToCache(List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedNotifications, jsonEncode(notifications));
  }

  Future<List<Map<String, dynamic>>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCachedNotifications);
      if (raw == null) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // NAVIGATION ON NOTIFICATION TAP
  // ─────────────────────────────────────────────────────────────
  void _onSelectNotification(NotificationResponse response) {
    if (response.payload != null) {
      _navigateToRoute(response.payload!);
    }
  }

  void _navigateToRoute(String route) {
    if (navigatorKey == null || navigatorKey!.currentContext == null) return;
    final context = navigatorKey!.currentContext!;

    Widget destination;
    switch (route) {
      case 'homework':
        destination = const HomeworkScreen();
        break;
      case 'announcements':
        destination = const AnnouncementsScreen();
        break;
      case 'events':
        destination = Container();
        break;
      case 'messages':
        destination = const MessagesScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination));
  }

  // ─────────────────────────────────────────────────────────────
  // PUBLIC: Manual trigger (for testing)
  // ─────────────────────────────────────────────────────────────
  Future<void> showTestNotification(String title, String body, String payloadRoute) async {
    await _showHeroBanner(title, body, payloadRoute);
    await _cacheNotification(title, body, payloadRoute);
  }

  /// Clear all cached notifications (e.g. on logout)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCachedNotifications);
  }

  /// Get cached notifications for display in NotificationsScreen (offline)
  Future<List<Map<String, dynamic>>> getCachedNotifications() async {
    return _loadFromCache();
  }
}

