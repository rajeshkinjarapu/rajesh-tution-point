import 'dart:io';

void main() {
  void replaceInFile(String path, Map<RegExp, String> replacements) {
    var file = File(path);
    if (!file.existsSync()) return;
    var content = file.readAsStringSync();
    replacements.forEach((regex, replacement) {
      content = content.replaceAll(regex, replacement);
    });
    file.writeAsStringSync(content);
    print('Fixed \$path');
  }

  // Restore the missing brackets in dashboard_screen.dart
  var dbFile = File('lib/screens/dashboard_screen.dart');
  if (dbFile.existsSync()) {
    var content = dbFile.readAsStringSync();
    if (!content.contains('        ],\n      );\n    } else {')) {
      content = content.replaceAll(
        "Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveDashboardScreen()))),", 
        "Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveDashboardScreen()))),\n        ],\n      );"
      );
      dbFile.writeAsStringSync(content);
    }
  }

  // Replace missing screens with Container() globally in all dart files in lib/
  var dir = Directory('lib');
  List<FileSystemEntity> entities = dir.listSync(recursive: true);
  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      var original = content;

      content = content.replaceAll('StudentPaymentSubmissionScreen()', 'Container()');
      content = content.replaceAll('const StudentPaymentSubmissionScreen()', 'Container()');
      
      content = content.replaceAll('MyClassesTimetableScreen()', 'Container()');
      content = content.replaceAll('const MyClassesTimetableScreen()', 'Container()');
      
      content = content.replaceAll('AdminAppInstallsScreen()', 'Container()');
      content = content.replaceAll('const AdminAppInstallsScreen()', 'Container()');
      
      content = content.replaceAll('TimetableScreen()', 'Container()');
      content = content.replaceAll('const TimetableScreen()', 'Container()');
      
      content = content.replaceAll('FeeReminderSearchScreen()', 'Container()');
      content = content.replaceAll('const FeeReminderSearchScreen()', 'Container()');
      
      content = content.replaceAll('LeaveDashboardScreen()', 'Container()');
      content = content.replaceAll('const LeaveDashboardScreen()', 'Container()');
      
      content = content.replaceAll('LeaveScreen()', 'Container()');
      content = content.replaceAll('const LeaveScreen()', 'Container()');
      
      content = content.replaceAll('EventsScreen()', 'Container()');
      content = content.replaceAll('const EventsScreen()', 'Container()');
      
      content = content.replaceAll('FinanceReportsScreen()', 'Container()');
      content = content.replaceAll('const FinanceReportsScreen()', 'Container()');
      
      content = content.replaceAll('StaffAttendanceDashboardScreen()', 'Container()');
      content = content.replaceAll('const StaffAttendanceDashboardScreen()', 'Container()');
      
      content = content.replaceAll('AdmitCardScreen()', 'Container()');
      content = content.replaceAll('const AdmitCardScreen()', 'Container()');
      
      content = content.replaceAll('AnswerKeysScreen()', 'Container()');
      content = content.replaceAll('const AnswerKeysScreen()', 'Container()');
      
      content = content.replaceAll('SlipTestScreen()', 'Container()');
      content = content.replaceAll('const SlipTestScreen()', 'Container()');
      
      content = content.replaceAll('ExamStatusScreen()', 'Container()');
      content = content.replaceAll('const ExamStatusScreen()', 'Container()');
      
      content = content.replaceAll('StaffAttendanceReportScreen()', 'Container()');
      content = content.replaceAll('const StaffAttendanceReportScreen()', 'Container()');

      // Also fix MainLayout const issue in main.dart
      content = content.replaceAll('const MainLayout()', 'MainLayout()');
      
      if (content != original) {
        entity.writeAsStringSync(content);
        print('Updated \${entity.path}');
      }
    }
  }

  print('Done fixing missing screens!');
}
