// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() {
  final arbDir = Directory('lib/l10n');

  if (!arbDir.existsSync()) {
    stderr.writeln('Directory lib/l10n not found');
    exit(1);
  }

  final arbFiles =
      arbDir.listSync().where((f) => f is File && f.path.endsWith('.arb')).cast<File>();

  for (final file in arbFiles) {
    final raw = file.readAsStringSync();
    final map = json.decode(raw) as Map<String, dynamic>;

    final locale = map['@@locale'];
    final rest = Map<String, dynamic>.from(map)..remove('@@locale');

    final grouped = <String, Map<String, dynamic>>{};

    for (final entry in rest.entries) {
      final key = entry.key;

      if (key.startsWith('@')) {
        final base = key.substring(1);
        grouped.putIfAbsent(base, () => {});
        grouped[base]!['@$base'] = entry.value;
      } else {
        grouped.putIfAbsent(key, () => {});
        grouped[key]![key] = entry.value;
      }
    }

    final sortedKeys = grouped.keys.toList()..sort();

    final result = <String, dynamic>{};

    if (locale != null) {
      result['@@locale'] = locale;
    }

    for (final k in sortedKeys) {
      final g = grouped[k]!;
      if (g.containsKey(k)) {
        result[k] = g[k];
      }
      if (g.containsKey('@$k')) {
        result['@$k'] = g['@$k'];
      }
    }

    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync('${encoder.convert(result)}\n');

    print('Sorted: ${file.path}');
  }
}
