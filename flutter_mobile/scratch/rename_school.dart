import 'dart:io';

void main() {
  void replaceInFile(String path, Map<RegExp, String> replacements) {
    var file = File(path);
    if (!file.existsSync()) return;
    var content = file.readAsStringSync();
    var original = content;
    replacements.forEach((regex, replacement) {
      content = content.replaceAll(regex, replacement);
    });
    if (content != original) {
      file.writeAsStringSync(content);
      print('Fixed \$path');
    }
  }

  var dir = Directory('lib');
  List<FileSystemEntity> entities = dir.listSync(recursive: true);
  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      replaceInFile(entity.path, {
        RegExp(r'Rajesh Tution Point', caseSensitive: false): 'Rajesh Tution Point',
        RegExp(r'Rajesh Tution Point', caseSensitive: false): 'Rajesh Tution Point',
        RegExp(r'Rajesh Tution Point', caseSensitive: false): 'Rajesh Tution Point',
        RegExp(r'jyschool', caseSensitive: false): 'rajeshtution',
        RegExp(r'School Office', caseSensitive: false): 'Tution Office',
        RegExp(r'School Management', caseSensitive: false): 'Tution Management',
      });
    }
  }

  print('Done renaming!');
}
