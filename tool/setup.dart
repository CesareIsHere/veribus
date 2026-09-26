// Turns a fresh copy of the template into your project.
//
//   dart run tool/setup.dart --name my_app --org com.acme --display-name "My App" \
//       --backend supabase --without payments,ai,push
//
// Run it once, right after "Use this template". Commit before running: it
// deletes files. `--dry-run` prints the plan without touching anything.
import 'dart:convert';
import 'dart:io';

const templateName = 'emiliano_cesare_flutter_template';
const templateOrg = 'com.emilianocesare';
const templateIosId = 'com.emilianocesare.emilianoCesareFlutterTemplate';
const templateDisplayName = 'Template';

const usage = '''
Usage: dart run tool/setup.dart [options]

  --name <snake_case>      Dart package name (e.g. my_app)
  --org <reverse.domain>   Bundle / application id prefix (e.g. com.acme)
  --display-name <name>    Name shown under the app icon
  --backend <a,b>          Backends to keep: rest, firebase, supabase (default: all).
                           The first one becomes BACKEND in staging/prod. Mock is always kept.
  --without <a,b,...>      Features to remove for good. Available:
                           demo, onboarding, social_login, connectivity, app_review, feedback,
                           biometric_lock, push, remote_config, analytics, payments, ai
  --dry-run                Print what would change
  --help
''';

Future<void> main(List<String> args) async {
  final opts = parseArgs(args);
  if (opts.containsKey('help')) return stdout.write(usage);

  final manifest = jsonDecode(File('tool/features.json').readAsStringSync()) as Map<String, dynamic>;
  final features = (manifest['features'] as Map<String, dynamic>).cast<String, Map<String, dynamic>>();
  final backends = (manifest['backends'] as Map<String, dynamic>).cast<String, Map<String, dynamic>>();

  final without = [
    for (final f in (opts['without'] ?? '').split(','))
      if (f.trim().isNotEmpty) f.trim(),
  ];
  final unknown = without.where((f) => !features.containsKey(f));
  if (unknown.isNotEmpty) _fail('Unknown feature(s): ${unknown.join(', ')}\n\n$usage');

  final kept = [
    for (final b in (opts['backend'] ?? backends.keys.join(',')).split(','))
      if (b.trim().isNotEmpty) b.trim(),
  ];
  if (kept.isEmpty || kept.any((b) => !backends.containsKey(b))) {
    _fail('--backend takes a comma-separated list of: ${backends.keys.join(', ')}');
  }
  final removedBackends = backends.keys.where((b) => !kept.contains(b)).toList();

  final name = opts['name'];
  if (name != null && !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) _fail('--name must be snake_case');
  final org = opts['org'];
  if (org != null && !RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$').hasMatch(org)) {
    _fail('--org must look like com.example');
  }

  // Marker tag -> manifest entry to remove.
  final removed = <String, Map<String, dynamic>>{
    for (final f in without) 'feature:$f': features[f]!,
    for (final b in removedBackends) 'backend:$b': backends[b]!,
  };
  final firebaseUsed =
      !removedBackends.contains('firebase') ||
      features.entries.any((e) => e.value['firebase'] == true && !without.contains(e.key));
  if (!firebaseUsed) removed['firebase'] = manifest['firebase'] as Map<String, dynamic>;

  print('Removing: ${removed.keys.isEmpty ? 'nothing' : removed.keys.join(', ')}');
  if (name != null || org != null) print('Renaming to ${org ?? templateOrg}.${name ?? templateName}');
  if (opts.containsKey('dry-run')) return;

  // 1. Remove features / backends.
  for (final MapEntry(key: tag, value: entry) in removed.entries) {
    for (final path in (entry['paths'] as List).cast<String>()) {
      final type = FileSystemEntity.typeSync(path);
      if (type == FileSystemEntityType.directory) Directory(path).deleteSync(recursive: true);
      if (type == FileSystemEntityType.file) {
        // Generated parts go with their source file.
        final base = path.replaceFirst(RegExp(r'\.dart$'), '');
        for (final f in [path, '$base.g.dart', '$base.freezed.dart']) {
          if (File(f).existsSync()) File(f).deleteSync();
        }
      }
    }
    for (final file in _files(['lib', 'test'], const ['.dart'])) {
      final source = file.readAsStringSync();
      final stripped = stripMarkers(source, tag);
      if (stripped != source) file.writeAsStringSync(stripped);
    }
    _edit('pubspec.yaml', (s) => removePackages(s, (entry['packages'] as List).cast<String>()));
    if (entry['flag'] case final String flag) {
      for (final env in _files(['env'], const ['.json'])) {
        _edit(env.path, (s) => s.replaceAll(RegExp('"$flag":\\s*true'), '"$flag": false'));
      }
    }
  }
  if (removedBackends.isNotEmpty) {
    for (final file in _files(['lib'], const ['.dart'])) {
      _edit(file.path, (s) => s.replaceAll('// backend:fallback ', ''));
    }
    for (final env in ['env/staging.json', 'env/prod.json']) {
      _edit(env, (s) => s.replaceAll(RegExp(r'"BACKEND":\s*"[a-z]+"'), '"BACKEND": "${kept.first}"'));
    }
  }

  // 2. Rename package, ids and display name.
  if (name != null || org != null) {
    final newName = name ?? templateName;
    final newOrg = org ?? templateOrg;
    const oldAndroidId = '$templateOrg.$templateName';
    final newAndroidId = '$newOrg.$newName';
    final activity = Directory('android/app/src/main/kotlin/${oldAndroidId.replaceAll('.', '/')}');
    if (activity.existsSync()) {
      final target = Directory('android/app/src/main/kotlin/${newAndroidId.replaceAll('.', '/')}')
        ..createSync(recursive: true);
      for (final f in activity.listSync().whereType<File>()) {
        f.renameSync('${target.path}/${f.uri.pathSegments.last}');
      }
    }
    final iosId = '$newOrg.${_camel(newName)}';
    for (final file in _files(['lib', 'test', 'android', 'ios', 'web', 'integration_test'], _textExtensions)) {
      _edit(
        file.path,
        (s) => s
            .replaceAll(oldAndroidId, newAndroidId)
            .replaceAll(templateIosId, iosId)
            .replaceAll('package:$templateName/', 'package:$newName/')
            .replaceAll(templateName, newName),
      );
    }
    _edit('pubspec.yaml', (s) => s.replaceFirst('name: $templateName', 'name: $newName'));
  }
  if (opts['display-name'] case final display?) {
    _edit(
      'android/app/src/main/AndroidManifest.xml',
      (s) => s.replaceFirst('android:label="$templateDisplayName"', 'android:label="$display"'),
    );
    _edit(
      'ios/Runner/Info.plist',
      (s) => s.replaceFirstMapped(
        RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'),
        (m) => '${m[1]}$display${m[2]}',
      ),
    );
    _edit(
      'web/index.html',
      (s) => s
          .replaceAll('>$templateDisplayName<', '>$display<')
          .replaceAll('content="$templateDisplayName"', 'content="$display"'),
    );
    _edit('web/manifest.json', (s) => s.replaceAll('"$templateDisplayName"', jsonEncode(display)));
    for (final env in _files(['env'], const ['.json'])) {
      _edit(
        env.path,
        (s) => s.replaceFirstMapped(
          RegExp(r'"APP_NAME": "Template( \w+)?"'),
          (m) => '"APP_NAME": ${jsonEncode('$display${m[1] ?? ''}')}',
        ),
      );
    }
  }

  // 3. Clean up imports left unused and reformat (best effort).
  for (final cmd in [
    ['flutter', 'pub', 'get'],
    ['dart', 'fix', '--apply'],
    ['dart', 'format', 'lib', 'test'],
  ]) {
    final r = Process.runSync(cmd.first, cmd.sublist(1), runInShell: true);
    print('${cmd.join(' ')} → ${r.exitCode == 0 ? 'ok' : 'failed, run it manually'}');
  }
  print('\nDone. Next: flutter analyze && flutter test, then see README "After setup".');
}

/// Removes `// <tag>:start` … `// <tag>:end` blocks and lines ending in `// <tag>`.
String stripMarkers(String source, String tag) {
  final t = RegExp.escape(tag);
  final start = RegExp('//\\s*$t:start\\s*\$');
  final end = RegExp('//\\s*$t:end\\s*\$');
  final single = RegExp('//\\s*$t\\s*\$');
  final out = <String>[];
  var skipping = false;
  for (final line in source.split('\n')) {
    if (skipping) {
      if (end.hasMatch(line)) skipping = false;
    } else if (start.hasMatch(line)) {
      skipping = true;
    } else if (!single.hasMatch(line)) {
      out.add(line);
    }
  }
  return out.join('\n');
}

/// Removes `  <package>: <version>` dependency lines from pubspec.yaml.
String removePackages(String pubspec, List<String> packages) =>
    packages.fold(pubspec, (s, p) => s.replaceAll(RegExp('^  ${RegExp.escape(p)}:.*\\r?\\n', multiLine: true), ''));

Map<String, String> parseArgs(List<String> args) {
  final opts = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) _fail('Unexpected argument: $arg\n\n$usage');
    final eq = arg.indexOf('=');
    if (eq != -1) {
      opts[arg.substring(2, eq)] = arg.substring(eq + 1);
    } else if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
      opts[arg.substring(2)] = args[++i];
    } else {
      opts[arg.substring(2)] = '';
    }
  }
  return opts;
}

const _textExtensions = [
  '.dart', '.yaml', '.json', '.kts', '.kt', '.xml', '.plist', '.pbxproj', '.html', '.swift', '.xcscheme', //
];

/// Text files under [dirs]. Symlinks are skipped (ios/Flutter/ephemeral has broken ones).
Iterable<File> _files(List<String> dirs, List<String> extensions) sync* {
  for (final dir in dirs.map(Directory.new)) {
    if (dir.existsSync()) yield* _walk(dir, extensions);
  }
}

/// Manual walk: skips generated folders and survives unreadable ones.
Iterable<File> _walk(Directory dir, List<String> extensions) sync* {
  const skip = {'ephemeral', '.symlinks', 'Pods', 'build', '.dart_tool', '.gradle'};
  final List<FileSystemEntity> entries;
  try {
    entries = dir.listSync(followLinks: false);
  } on FileSystemException {
    return;
  }
  for (final entry in entries) {
    final name = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (entry is Directory && !skip.contains(name)) {
      yield* _walk(entry, extensions);
    } else if (entry is File && extensions.any(entry.path.endsWith)) {
      yield entry;
    }
  }
}

void _edit(String path, String Function(String) change) {
  final file = File(path);
  if (!file.existsSync()) return;
  final source = file.readAsStringSync();
  final updated = change(source);
  if (updated != source) file.writeAsStringSync(updated);
}

String _camel(String snake) {
  final parts = snake.split('_');
  return parts.first + parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(64);
}
