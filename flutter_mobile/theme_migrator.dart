import 'dart:io';

void main() {
  final dir = Directory('lib/screens');
  if (!dir.existsSync()) {
    print('lib/screens not found');
    return;
  }

  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    // 1. Change card backgrounds
    content = content.replaceAll('color: const Color(0xFF1E293B)', 'color: Colors.white');

    // 2. Fix GoogleFonts styles
    final gfRegex = RegExp(r'GoogleFonts\.[a-zA-Z]+\(([^)]+)\)', multiLine: true);
    content = content.replaceAllMapped(gfRegex, (match) {
      String block = match.group(0)!;
      block = block.replaceAll('color: Colors.white', 'color: const Color(0xFF1E293B)');
      block = block.replaceAll('color: const Color(0xFFFFFFFF)', 'color: const Color(0xFF1E293B)');
      block = block.replaceAll('color: const Color(0xFFE2E8F0)', 'color: const Color(0xFF64748B)');
      block = block.replaceAll('color: const Color(0xFF94A3B8)', 'color: const Color(0xFF475569)');
      return block;
    });

    // 3. Fix Icons
    final iconRegex = RegExp(r'Icon\(([^)]+)\)', multiLine: true);
    content = content.replaceAllMapped(iconRegex, (match) {
      String block = match.group(0)!;
      block = block.replaceAll('color: Colors.white', 'color: const Color(0xFF64748B)');
      block = block.replaceAll('color: const Color(0xFFE2E8F0)', 'color: const Color(0xFF64748B)');
      return block;
    });

    if (content != original) {
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
