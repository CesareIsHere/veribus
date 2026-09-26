import 'package:emiliano_cesare_flutter_template/features/app_gate/providers/app_gate_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isVersionLower', () {
    expect(isVersionLower('1.2.3', '1.10.0'), isTrue);
    expect(isVersionLower('1.2.3+45', '1.2.3'), isFalse);
    expect(isVersionLower('2.0', '1.9.9'), isFalse);
    expect(isVersionLower('1.0.0', '0.0.0'), isFalse);
  });
}
