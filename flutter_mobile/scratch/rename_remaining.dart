import 'dart:io';

void main() {
  final directory = Directory('.');
  
  final replaceMap = {
    'jy_school_flutter': 'Rajesh Tution Point',
    'JY - Student': 'Rajesh Tution - Student',
    'JY - Teacher': 'Rajesh Tution - Teacher',
    'JY - Admin': 'Rajesh Tution - Admin',
    'JY INTERNATIONAL SCHOOL': 'RAJESH TUTION POINT',
    'JY International School': 'Rajesh Tution Point',
    'com.jyschool.erp': 'com.rajeshtution.erp',
    'jyschool_alerts': 'rajeshtution_alerts',
  };

  final files = directory.listSync(recursive: true).whereType<File>();
  
  for (final file in files) {
    if (file.path.contains('.git') || file.path.contains('build\\') || file.path.endsWith('.png') || file.path.endsWith('.jpg') || file.path.endsWith('.wav')) continue;
    
    try {
      String content = file.readAsStringSync();
      bool changed = false;
      
      replaceMap.forEach((key, value) {
        if (content.contains(key)) {
          content = content.replaceAll(key, value);
          changed = true;
        }
      });
      
      if (changed) {
        file.writeAsStringSync(content);
        print('Updated: ${file.path}');
      }
    } catch (e) {
      // Ignore binary files or read errors
    }
  }
}
