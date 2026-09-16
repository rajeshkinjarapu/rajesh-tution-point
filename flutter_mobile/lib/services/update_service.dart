import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';

class UpdateService {
  static const String updateUrl = 'http://YOUR_LOCAL_IP:19998/app-version.json';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(updateUrl)).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String latestVersion = data['latestVersion'] ?? '1.0.0';
        final String flavorName = AppConfig.current.flavor.name;
        final String downloadUrl = data['downloadUrls']?[flavorName] ?? data['downloadUrl'] ?? '';
        final bool forceUpdate = data['forceUpdate'] ?? false;
        final String releaseNotes = data['releaseNotes'] ?? 'Exciting new features, UI enhancements, and bug fixes are available.';

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;

        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          if (context.mounted) {
            _showUpdateDialog(context, currentVersion, latestVersion, releaseNotes, downloadUrl, forceUpdate);
          }
        }
      }
    } catch (e) {
      debugPrint("Update check failed (silently skipped): $e");
    }
  }

  static bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    // Remove build number (e.g., "1.0.2+3" -> "1.0.2")
    String currentClean = currentVersion.split('+')[0];
    String latestClean = latestVersion.split('+')[0];

    List<String> currentParts = currentClean.split('.');
    List<String> latestParts = latestClean.split('.');

    for (int i = 0; i < 3; i++) {
      int current = int.tryParse(currentParts.length > i ? currentParts[i] : '0') ?? 0;
      int latest = int.tryParse(latestParts.length > i ? latestParts[i] : '0') ?? 0;

      if (latest > current) return true;
      if (latest < current) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String currentVersion,
    String latestVersion,
    String releaseNotes,
    String downloadUrl,
    bool forceUpdate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (BuildContext ctx) {
        return PopScope(
          canPop: !forceUpdate,
          child: _ModernUpdateDialog(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseNotes: releaseNotes,
            downloadUrl: downloadUrl,
            forceUpdate: forceUpdate,
          ),
        );
      },
    );
  }
}

class _ModernUpdateDialog extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final bool forceUpdate;

  const _ModernUpdateDialog({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.forceUpdate,
  });

  @override
  State<_ModernUpdateDialog> createState() => _ModernUpdateDialogState();
}

class _ModernUpdateDialogState extends State<_ModernUpdateDialog> with SingleTickerProviderStateMixin {
  bool isDownloading = false;
  double progress = 0.0;
  String downloadedText = '';
  String status = 'Ready to download';
  String? errorMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _downloadAndInstall() async {
    setState(() {
      isDownloading = true;
      errorMessage = null;
      status = 'Connecting to server...';
      progress = 0.0;
      downloadedText = 'Starting download...';
    });

    try {
      Directory? dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      String fileName = "Rajesh_Tution_v${widget.latestVersion}.apk";
      String savePath = "${dir.path}/$fileName";

      // Remove existing temp file if present
      final oldFile = File(savePath);
      if (await oldFile.exists()) {
        try {
          await oldFile.delete();
        } catch (_) {}
      }

      Dio dio = Dio();
      await dio.download(
        widget.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final double p = received / total;
            final double receivedMb = received / (1024 * 1024);
            final double totalMb = total / (1024 * 1024);
            setState(() {
              progress = p;
              status = 'Downloading update... ${(p * 100).toStringAsFixed(0)}%';
              downloadedText = '${receivedMb.toStringAsFixed(1)} MB / ${totalMb.toStringAsFixed(1)} MB';
            });
          } else {
            final double receivedMb = received / (1024 * 1024);
            setState(() {
              status = 'Downloading update...';
              downloadedText = '${receivedMb.toStringAsFixed(1)} MB downloaded';
            });
          }
        },
      );

      setState(() {
        status = 'Opening package installer...';
        progress = 1.0;
      });

      // Directly launch Android package installer on screen
      final result = await OpenFile.open(
        savePath,
        type: "application/vnd.android.package-archive",
      );

      if (result.type != ResultType.done) {
        setState(() {
          errorMessage = 'Could not open installer: ${result.message}';
          isDownloading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Download error: $e';
        isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppConfig.current.primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 16,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Gradient Header with Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, const Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'App Update Available',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'v${widget.currentVersion}',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                        ),
                        Text(
                          'v${widget.latestVersion}',
                          style: GoogleFonts.poppins(color: const Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  // Error Message
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF991B1B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Progress Indicator while Downloading
                  if (isDownloading) ...[
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          status,
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        ),
                        Text(
                          downloadedText,
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: themeColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // Buttons
                  Row(
                    children: [
                      if (!widget.forceUpdate && !isDownloading) ...[
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              'Remind Later',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: widget.forceUpdate ? 1 : 2,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [themeColor, const Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isDownloading ? null : _downloadAndInstall,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isDownloading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Updating...',
                                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Update Now',
                                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                          ),
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
    );
  }
}
