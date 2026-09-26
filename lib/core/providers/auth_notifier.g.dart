// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Current user (null = signed out). Drives router redirects.
///
/// Actions just forward to the repository: the new user arrives through
/// `authStateChanges()`, so there is a single source of truth.

@ProviderFor(AuthNotifier)
final authProvider = AuthNotifierProvider._();

/// Current user (null = signed out). Drives router redirects.
///
/// Actions just forward to the repository: the new user arrives through
/// `authStateChanges()`, so there is a single source of truth.
final class AuthNotifierProvider extends $StreamNotifierProvider<AuthNotifier, UserModel?> {
  /// Current user (null = signed out). Drives router redirects.
  ///
  /// Actions just forward to the repository: the new user arrives through
  /// `authStateChanges()`, so there is a single source of truth.
  AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();
}

String _$authNotifierHash() => r'88c1f41453d4020b72e38b8c69a7d3033cd2064a';

/// Current user (null = signed out). Drives router redirects.
///
/// Actions just forward to the repository: the new user arrives through
/// `authStateChanges()`, so there is a single source of truth.

abstract class _$AuthNotifier extends $StreamNotifier<UserModel?> {
  Stream<UserModel?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserModel?>, UserModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserModel?>, UserModel?>,
              AsyncValue<UserModel?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
