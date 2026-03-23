import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory('lib');
  final rxIgnore = RegExp(r'//\s*ignore(_for_file)?\b');
  var changed = 0;
  for (final f in root.listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    final text = f.readAsStringSync();
    final rawLines = const LineSplitter().convert(text);
    final out = <String>[];
    for (final line in rawLines) {
      final s = line.replaceFirst(RegExp(r'^\s+'), '');
      if (s.startsWith('///')) continue;
      if (s.startsWith('//')) {
        if (rxIgnore.hasMatch(s)) {
          out.add(line);
        }
        continue;
      }
      out.add(line);
    }
    final next = '${out.join('\n')}${text.endsWith('\n') ? '\n' : ''}';
    if (next != text) {
      f.writeAsStringSync(next);
      changed++;
      stdout.writeln(f.path);
    }
  }
  stdout.writeln('Updated $changed files.');
}
