import 'package:flutter_test/flutter_test.dart';
import 'package:veribus/features/settings/components/settings_button.dart';
import 'package:veribus/models/user/user_model.dart';

void main() {
  test('the initials of the avatar: two for a full name, one for a single name, the email as a last resort', () {
    expect(SettingsButton.initialsOf(const UserModel(id: '1', email: 'a@b.it', displayName: 'Emiliano Cesare')), 'EC');
    expect(SettingsButton.initialsOf(const UserModel(id: '1', email: 'a@b.it', displayName: ' maria ')), 'M');
    expect(SettingsButton.initialsOf(const UserModel(id: '1', email: 'zeta@b.it')), 'ZE');
    expect(SettingsButton.initialsOf(null), '?');
  });
}
