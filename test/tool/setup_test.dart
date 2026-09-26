import 'package:flutter_test/flutter_test.dart';

import '../../tool/setup.dart';

void main() {
  test('stripMarkers removes blocks and tagged lines only', () {
    const source = '''
import 'a.dart';
import 'push.dart'; // feature:push
import 'push_x.dart'; // feature:push_x
void main() {
  // feature:push:start
  initPush();
  // feature:push:end
  run();
}''';
    expect(stripMarkers(source, 'feature:push'), '''
import 'a.dart';
import 'push_x.dart'; // feature:push_x
void main() {
  run();
}''');
  });

  test('removePackages drops only the named dependency lines', () {
    const pubspec = 'dependencies:\n  dio: ^5.0.0\n  dio_x: ^1.0.0\n  local_auth: ^3.0.2\n';
    expect(removePackages(pubspec, ['dio', 'local_auth']), 'dependencies:\n  dio_x: ^1.0.0\n');
  });

  test('parseArgs supports both --k v and --k=v', () {
    expect(parseArgs(['--name', 'my_app', '--without=push,ai', '--dry-run']), {
      'name': 'my_app',
      'without': 'push,ai',
      'dry-run': '',
    });
  });
}
