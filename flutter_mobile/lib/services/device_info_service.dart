import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'api_service.dart';

class DeviceInfoService {
  static Future<void> updateAppInfo() async {
    if (kIsWeb) return; // Skip for web
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      String deviceModel = 'Unknown Device';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
      }

      await ApiService.updateAppInfo({
        'deviceModel': deviceModel,
        'appVersion': packageInfo.version,
      });
    } catch (e) {
      debugPrint('Failed to update app info: $e');
    }
  }
}
