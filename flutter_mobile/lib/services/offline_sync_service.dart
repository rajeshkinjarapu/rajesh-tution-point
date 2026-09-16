import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'api_service.dart';

class OfflineSyncService {
  static const String _queueKey = 'offline_sync_queue';
  static final _uuid = const Uuid();
  static bool _isSyncing = false;

  // Initialize and listen to network changes
  static void initialize() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline) {
        _syncOfflineData();
      }
    });
  }

  // Enqueue a request that failed due to network error
  static Future<void> enqueueRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_queueKey) ?? '[]';
    List<dynamic> queue = jsonDecode(queueStr);

    final requestItem = {
      'id': _uuid.v4(),
      'method': method.toUpperCase(),
      'endpoint': endpoint,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    };

    queue.add(requestItem);
    await prefs.setString(_queueKey, jsonEncode(queue));
    debugPrint('Queued offline request: $method $endpoint');
  }

  // Process the queue
  static Future<void> _syncOfflineData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final queueStr = prefs.getString(_queueKey);
      if (queueStr == null) return;

      List<dynamic> queue = jsonDecode(queueStr);
      if (queue.isEmpty) return;

      debugPrint('Syncing ${queue.length} offline requests...');
      List<dynamic> failedRequests = [];
      final token = await ApiService.getToken();
      if (token == null) {
        // Can't sync without token, keep in queue
        _isSyncing = false;
        return;
      }

      for (var req in queue) {
        bool success = false;
        try {
          final uri = Uri.parse('${ApiService.baseUrl}${req['endpoint']}');
          final headers = {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': '69420',
            'Authorization': 'Bearer $token',
          };

          http.Response response;
          switch (req['method']) {
            case 'POST':
              response = await http.post(uri, headers: headers, body: req['body'] != null ? jsonEncode(req['body']) : null);
              break;
            case 'PUT':
              response = await http.put(uri, headers: headers, body: req['body'] != null ? jsonEncode(req['body']) : null);
              break;
            case 'DELETE':
              response = await http.delete(uri, headers: headers);
              break;
            default:
              continue; // Invalid method
          }

          if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
            success = true;
            debugPrint('Synced successfully: ${req['method']} ${req['endpoint']}');
          }
        } catch (e) {
          debugPrint('Failed to sync ${req['method']} ${req['endpoint']}: $e');
        }

        if (!success) {
          failedRequests.add(req);
        }
      }

      // Update queue with only the ones that failed again
      await prefs.setString(_queueKey, jsonEncode(failedRequests));

    } catch (e) {
      debugPrint('Error during offline sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Expose manual sync method for UI
  static Future<void> syncNow() async {
    await _syncOfflineData();
  }
}
