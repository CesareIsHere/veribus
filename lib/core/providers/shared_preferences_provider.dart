import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_preferences_provider.g.dart';

/// Loaded once in `main()` and injected with an override, so reads are sync.
@Riverpod(keepAlive: true)
SharedPreferencesWithCache sharedPreferences(Ref ref) =>
    throw UnimplementedError('Override sharedPreferencesProvider in main()');
