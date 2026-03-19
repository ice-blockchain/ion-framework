// SPDX-License-Identifier: ice License 1.0
//
// Translates missing ARB strings using OpenAI. Run from repo root after:
//   flutter gen-l10n
// Requires OPENAI_API_KEY in the environment.
//
// Usage: dart run tools/translate_missing.dart [options]
//   --dry-run       Print what would be translated without calling the API or writing files.
//   --commit        Commit and push ARB changes (use only on CI, on a feature branch). Without this, no git operations run (local default).
//   --base-ref=REF  Compare app_en.arb with REF (e.g. origin/master) and re-translate keys whose English changed in all locales. Use in CI to sync PR changes. Can also set BASE_REF env.

import 'dart:convert';
import 'dart:io';

const _arbDir = 'lib/l10n';
const _templateArb = 'app_en.arb';
const _untranslatedFile = 'untranslated_messages.txt';
const _openAiEndpoint = 'https://api.openai.com/v1/chat/completions';
const _model = 'gpt-4o-mini';

/// Locale code -> full language name for the OpenAI prompt.
const _localeToLanguage = {
  'ar': 'Arabic',
  'bg': 'Bulgarian',
  'de': 'German',
  'es': 'Spanish',
  'fr': 'French',
  'it': 'Italian',
  'ko': 'Korean',
  'pl': 'Polish',
  'pt': 'Portuguese',
  'ro': 'Romanian',
  'ru': 'Russian',
  'tr': 'Turkish',
  'zh': 'Chinese',
};

void main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final doCommit = args.contains('--commit');
  final baseRef = _parseBaseRef(args);

  final cwd = Directory.current.path;
  final untranslatedPath = '$cwd/$_untranslatedFile';
  final arbDirPath = '$cwd/$_arbDir';

  var untranslated = <String, List<String>>{};
  if (File(untranslatedPath).existsSync()) {
    final content = await File(untranslatedPath).readAsString();
    untranslated = _parseUntranslated(content);
  } else if (baseRef == null) {
    stderr.writeln('$_untranslatedFile not found. Run "flutter gen-l10n" first.');
    exit(1);
  }

  final templatePath = '$arbDirPath/$_templateArb';
  if (!File(templatePath).existsSync()) {
    stderr.writeln('Template $_templateArb not found at $templatePath');
    exit(1);
  }

  final templateArb = _parseArb(await File(templatePath).readAsString());

  // Keys in app_en.arb whose source text (or @key metadata) changed vs base ref — need re-translation in all locales.
  var changedAddedKeys = <String>{};
  var changedModifiedKeys = <String>{};
  if (baseRef != null) {
    final changed = await _getChangedEnKeysDetailed(cwd, baseRef, templateArb);
    changedAddedKeys = changed.added;
    changedModifiedKeys = changed.modified;
    final totalChanged = changedAddedKeys.length + changedModifiedKeys.length;
    if (totalChanged > 0) {
      stdout.writeln(
        'Keys with changed English (vs $baseRef): $totalChanged '
        '(added: ${changedAddedKeys.length}, modified: ${changedModifiedKeys.length})',
      );
    }
  }

  // All target locales: from untranslated_messages + existing app_XX.arb (except en).
  final allLocales = _allTargetLocales(arbDirPath, untranslated.keys.toList());

  // Merge: per locale, translate missing + changed keys (deduplicated).
  // - Modified English keys: always re-translate (overwrites locale values)
  // - Added English keys: translate only if the locale doesn't already have the key
  final toTranslate = await _mergeKeysToTranslate(
    arbDirPath,
    untranslated,
    changedAddedKeys,
    changedModifiedKeys,
    allLocales,
    baseRef: baseRef,
    cwd: cwd,
  );

  if (toTranslate.isEmpty) {
    stdout.writeln('No translations to generate.');
    exit(0);
  }

  final totalKeys = toTranslate.values.fold<int>(0, (s, keys) => s + keys.length);
  stdout.writeln('Keys to translate: $totalKeys across ${toTranslate.length} locale(s).');

  final apiKey = await _resolveOpenAiApiKey(cwd);
  if (!dryRun && (apiKey == null || apiKey.isEmpty)) {
    stderr.writeln(
      'OPENAI_API_KEY is not set in the environment and could not be found in .env or .app.env.\n'
      'Set it via:\n'
      '  export OPENAI_API_KEY=...    # shell / local\n'
      'or add it to your env files and re-run configure_env.sh.',
    );
    exit(1);
  }

  if (dryRun) {
    for (final e in toTranslate.entries) {
      stdout.writeln('  ${e.key}: ${e.value.length} keys');
    }
    exit(0);
  }

  var translated = 0;
  for (final localeEntry in toTranslate.entries) {
    final locale = localeEntry.key;
    final keysToTranslate = localeEntry.value;
    final language = _localeToLanguage[locale] ?? locale;
    final targetPath = '$arbDirPath/app_$locale.arb';
    var targetArb = <String, dynamic>{};
    if (File(targetPath).existsSync()) {
      targetArb = _parseArb(await File(targetPath).readAsString());
    } else {
      targetArb['@@locale'] = locale;
    }

    for (final key in keysToTranslate) {
      final source = templateArb[key] as String?;
      if (source == null) continue;

      final translatedText = await _translate(apiKey!, source, language);
      if (translatedText == null) {
        stderr.writeln('Failed to translate: $key for $locale');
        continue;
      }

      targetArb[key] = translatedText;
      final metaKey = '@$key';
      if (templateArb.containsKey(metaKey)) {
        targetArb[metaKey] = templateArb[metaKey];
      }
      translated++;
      stdout.writeln('  $locale: $key');
    }

    final merged = _mergeArbInTemplateOrder(templateArb, targetArb, locale);
    await _writeArb(targetPath, merged);
  }

  if (translated == 0) {
    stdout.writeln('No strings were translated.');
    exit(0);
  }

  if (!doCommit) {
    stdout.writeln(
      'Done. Translated $translated string(s). Not committing (use --commit on CI to commit and push).',
    );
    exit(0);
  }

  final branch = await _getCurrentBranch();
  if (branch == null) {
    stderr.writeln('Could not determine current git branch.');
    exit(1);
  }
  if (_isProtectedBranch(branch)) {
    stderr.writeln(
      'Commit is only allowed on feature branches, not on $branch.\n'
      'Refusing to commit/push to avoid modifying master or release branches.',
    );
    exit(1);
  }

  final hasChanges = await _hasGitChanges();
  if (!hasChanges) {
    stdout.writeln('No ARB changes detected after translation.');
    exit(0);
  }

  try {
    await _gitCommitAndPush();
  } catch (e, st) {
    stderr
      ..writeln('Git commit/push failed: $e')
      ..writeln(st);
    exit(1);
  }

  stdout.writeln('Translations committed and pushed to $branch.');
  exit(0);
}

String? _parseBaseRef(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--base-ref=')) {
      final ref = arg.substring('--base-ref='.length).trim();
      if (ref.isNotEmpty) return ref;
    }
  }
  return Platform.environment['BASE_REF'];
}

/// Parses untranslated_messages.txt (JSON: {"locale": ["key1", ...], ...}).
Map<String, List<String>> _parseUntranslated(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return {};
  try {
    final map = jsonDecode(trimmed) as Map<String, dynamic>;
    return map.map((locale, value) {
      final list = value as List<dynamic>;
      return MapEntry(locale, list.map((e) => e as String).toList());
    });
  } catch (_) {
    return {};
  }
}

/// Returns message keys in current app_en.arb that are added vs modified (vs [baseRef]).
Future<({Set<String> added, Set<String> modified})> _getChangedEnKeysDetailed(
  String cwd,
  String baseRef,
  Map<String, dynamic> currentArb,
) async {
  final result = await Process.run(
    'git',
    ['show', '$baseRef:$_arbDir/$_templateArb'],
    runInShell: true,
    workingDirectory: cwd,
  );
  if (result.exitCode != 0) {
    return (added: <String>{}, modified: <String>{});
  }
  final oldContent = result.stdout as String;
  if (oldContent.trim().isEmpty) {
    return (
      added: currentArb.keys.where((k) => !k.startsWith('@') && k != '@@locale').toSet(),
      modified: <String>{},
    );
  }
  Map<String, dynamic> oldArb;
  try {
    oldArb = _parseArb(oldContent);
  } catch (_) {
    return (added: <String>{}, modified: <String>{});
  }
  final added = <String>{};
  final modified = <String>{};
  for (final key in currentArb.keys) {
    if (key.startsWith('@') || key == '@@locale') continue;
    final currentVal = currentArb[key];
    final oldVal = oldArb[key];
    if (oldVal == null) {
      added.add(key);
      continue;
    }
    final metaKey = '@$key';
    final valChanged = currentVal != oldVal;
    // jsonDecode produces Map/List instances; default `==` for Map compares identity,
    // so we need deep equality for metadata objects (placeholders, descriptions, etc.).
    final metaChanged = !_deepEquals(currentArb[metaKey], oldArb[metaKey]);
    if (valChanged || metaChanged) modified.add(key);
  }
  return (added: added, modified: modified);
}

/// All target locale codes: from [fromUntranslated] plus any app_XX.arb present (except en).
List<String> _allTargetLocales(String arbDirPath, List<String> fromUntranslated) {
  final set = fromUntranslated.toSet();
  final dir = Directory(arbDirPath);
  if (!dir.existsSync()) return set.toList()..sort();
  for (final e in dir.listSync()) {
    if (e is! File) continue;
    final name = e.uri.pathSegments.last;
    if (!name.startsWith('app_') || !name.endsWith('.arb')) continue;
    final locale = name.substring(4, name.length - 4);
    if (locale != 'en') set.add(locale);
  }
  return set.toList()..sort();
}

/// Merge untranslated (per locale) with changed keys. Returns map locale -> list of keys to translate.
Future<Map<String, List<String>>> _mergeKeysToTranslate(
  String arbDirPath,
  Map<String, List<String>> untranslated,
  Set<String> changedAddedKeys,
  Set<String> changedModifiedKeys,
  List<String> allLocales, {
  required String? baseRef,
  required String cwd,
}) async {
  final out = <String, List<String>>{};

  for (final locale in allLocales) {
    final existingKeys = <String>{};
    final targetPath = '$arbDirPath/app_$locale.arb';
    Map<String, dynamic>? currentLocaleArb;
    if (File(targetPath).existsSync()) {
      try {
        currentLocaleArb = _parseArb(File(targetPath).readAsStringSync());
        for (final k in currentLocaleArb.keys) {
          if (k.startsWith('@') || k == '@@locale') continue;
          existingKeys.add(k);
        }
      } catch (_) {
        // If a locale ARB can't be parsed, fall back to translating based on untranslated + modified keys.
      }
    }

    final set = (untranslated[locale] ?? []).toSet();

    // For modified-English keys, don't keep re-translating if the locale value was
    // already updated in this branch. We treat "needs translation" as:
    // - key missing in current locale, or
    // - current locale value still matches baseRef's value (i.e., not updated yet), or
    // - baseRef doesn't have the locale/key (new locale/key in branch).
    if (changedModifiedKeys.isNotEmpty) {
      if (baseRef == null || currentLocaleArb == null) {
        set.addAll(changedModifiedKeys);
      } else {
        final baseLocaleArb = await _tryLoadArbFromGit(
          cwd: cwd,
          ref: baseRef,
          path: '$_arbDir/app_$locale.arb',
        );
        for (final key in changedModifiedKeys) {
          final currentVal = currentLocaleArb[key];
          if (currentVal == null) {
            set.add(key);
            continue;
          }
          final baseVal = baseLocaleArb?[key];
          if (baseVal == null) {
            set.add(key);
            continue;
          }
          if (currentVal == baseVal) {
            set.add(key);
          }
        }
      }
    }

    for (final key in changedAddedKeys) {
      if (!existingKeys.contains(key)) set.add(key);
    }
    if (set.isEmpty) continue;
    out[locale] = set.toList()..sort();
  }
  return out;
}

/// Parses ARB JSON; preserves key order via LinkedHashMap from jsonDecode.
Map<String, dynamic> _parseArb(String content) {
  return jsonDecode(content) as Map<String, dynamic>;
}

bool _deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;

  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }

  return a == b;
}

Future<Map<String, dynamic>?> _tryLoadArbFromGit({
  required String cwd,
  required String ref,
  required String path,
}) async {
  final result = await Process.run(
    'git',
    ['show', '$ref:$path'],
    runInShell: true,
    workingDirectory: cwd,
  );
  if (result.exitCode != 0) return null;
  final content = (result.stdout as String).trim();
  if (content.isEmpty) return null;
  try {
    return _parseArb(content);
  } catch (_) {
    return null;
  }
}

/// Replaces placeholders with tokens for the API; returns (modified string, ordered list of placeholders).
(List<String>, String) _replacePlaceholdersForTranslation(String text) {
  final placeholders = <String>[];
  var result = text;

  // {name}, {amount}, etc.
  result = result.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
    final placeholder = m.group(0)!;
    final index = placeholders.indexOf(placeholder);
    if (index >= 0) return '__PH_${index}__';
    placeholders.add(placeholder);
    return '__PH_${placeholders.length - 1}__';
  });

  // [[:link]]...[[/:link]]
  result = result.replaceAllMapped(RegExp(r'\[\[:link\]\](.*?)\[\[\/:link\]\]', dotAll: true), (m) {
    final full = m.group(0)!;
    final index = placeholders.indexOf(full);
    if (index >= 0) return '__PH_${index}__';
    placeholders.add(full);
    return '__PH_${placeholders.length - 1}__';
  });

  return (placeholders, result);
}

String _restorePlaceholders(String text, List<String> placeholders) {
  var result = text;
  for (var i = 0; i < placeholders.length; i++) {
    result = result.replaceAll('__PH_${i}__', placeholders[i]);
  }
  return result;
}

Future<String?> _translate(String apiKey, String source, String targetLanguage) async {
  final (placeholders, textForApi) = _replacePlaceholdersForTranslation(source);
  final prompt = 'Translate the following English app string to $targetLanguage. '
      'Keep any placeholders like __PH_0__, __PH_1__ exactly as-is (do not translate them). '
      'Reply with only the translated string, no quotes or explanation.\n\n$textForApi';

  final body = {
    'model': _model,
    'messages': [
      {'role': 'user', 'content': prompt},
    ],
    'temperature': 0.3,
  };

  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(_openAiEndpoint));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer $apiKey');
    request.write(jsonEncode(body));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      stderr.writeln('OpenAI API error ${response.statusCode}: $responseBody');
      return null;
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    final content = choices?.isNotEmpty ?? false
        ? (choices!.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?
        : null;
    final translated = content?['content'] as String?;
    if (translated == null || translated.isEmpty) return null;

    var trimmed = translated.trim();
    if (trimmed.length >= 2 &&
        (trimmed.startsWith('"') && trimmed.endsWith('"') ||
            trimmed.startsWith("'") && trimmed.endsWith("'"))) {
      trimmed = trimmed.substring(1, trimmed.length - 1);
    }
    return _restorePlaceholders(trimmed, placeholders);
  } catch (e, st) {
    stderr
      ..writeln('Translation request failed: $e')
      ..writeln(st);
    return null;
  } finally {
    client.close();
  }
}

/// Merges target ARB into template key order; uses template for @@locale and metadata keys.
Map<String, dynamic> _mergeArbInTemplateOrder(
  Map<String, dynamic> template,
  Map<String, dynamic> target,
  String targetLocale,
) {
  final merged = <String, dynamic>{};
  for (final key in template.keys) {
    if (key == '@@locale') {
      merged[key] = targetLocale;
    } else if (key.startsWith('@')) {
      merged[key] = template[key];
    } else {
      merged[key] = target[key] ?? template[key];
    }
  }
  return merged;
}

Future<void> _writeArb(String path, Map<String, dynamic> arb) async {
  const encoder = JsonEncoder.withIndent('  ');
  await File(path).writeAsString('${encoder.convert(arb)}\n');
}

Future<String?> _resolveOpenAiApiKey(String cwd) async {
  final fromEnv = Platform.environment['OPENAI_API_KEY'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

  final envFile = File('$cwd/.env');
  if (envFile.existsSync()) {
    final key = _readKeyFromEnvFile(envFile, 'OPENAI_API_KEY');
    if (key != null && key.isNotEmpty) return key;
  }

  final appEnvFile = File('$cwd/.app.env');
  if (appEnvFile.existsSync()) {
    final key = _readKeyFromEnvFile(appEnvFile, 'OPENAI_API_KEY');
    if (key != null && key.isNotEmpty) return key;
  }

  return null;
}

String? _readKeyFromEnvFile(File file, String key) {
  final prefix = '$key=';
  final lines = file.readAsLinesSync();
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#') || trimmed.isEmpty) continue;
    if (trimmed.startsWith(prefix)) {
      return trimmed.substring(prefix.length);
    }
  }
  return null;
}

Future<String?> _getCurrentBranch() async {
  final result = await Process.run(
    'git',
    ['rev-parse', '--abbrev-ref', 'HEAD'],
    runInShell: true,
  );
  if (result.exitCode != 0) return null;
  final branch = (result.stdout as String).trim();
  // Detached HEAD (e.g. CI pull_request checkout): use GitHub Actions branch when available.
  if (branch == 'HEAD') {
    final headRef = Platform.environment['GITHUB_HEAD_REF'];
    if (headRef != null && headRef.isNotEmpty) return headRef;
    return null;
  }
  return branch;
}

bool _isProtectedBranch(String branch) {
  if (branch == 'master') return true;
  if (branch == 'release_candidate') return true;
  if (branch.startsWith('release/')) return true;
  return false;
}

Future<bool> _hasGitChanges() async {
  final result = await Process.run(
    'git',
    ['status', '--porcelain', 'lib/l10n'],
    runInShell: true,
  );
  if (result.exitCode != 0) {
    stderr.writeln('git status failed: ${result.stderr}');
    return false;
  }
  return (result.stdout as String).trim().isNotEmpty;
}

Future<void> _gitCommitAndPush() async {
  const filesPattern = 'lib/l10n';

  final addResult = await Process.run(
    'git',
    ['add', filesPattern],
    runInShell: true,
  );
  if (addResult.exitCode != 0) {
    throw Exception('git add failed: ${addResult.stderr}');
  }

  final commitResult = await Process.run(
    'git',
    [
      'commit',
      '-m',
      'chore(l10n): auto-translate missing strings',
    ],
    runInShell: true,
  );

  if (commitResult.exitCode != 0 && (commitResult.stderr as String).contains('nothing to commit')) {
    return;
  }
  if (commitResult.exitCode != 0) {
    throw Exception('git commit failed: ${commitResult.stderr}');
  }

  // In detached HEAD (e.g. CI), push explicitly to the target branch.
  final branch = await _getCurrentBranch();
  if (branch == null || branch.isEmpty) {
    throw Exception(
      'Could not determine branch for push (detached HEAD?). '
      'On CI, set GITHUB_HEAD_REF or run from a branch.',
    );
  }
  final pushResult = await Process.run(
    'git',
    ['push', 'origin', 'HEAD:refs/heads/$branch'],
    runInShell: true,
  );
  if (pushResult.exitCode != 0) {
    throw Exception('git push failed: ${pushResult.stderr}');
  }
}
