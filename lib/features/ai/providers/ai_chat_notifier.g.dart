// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Chat transcript. The last message grows while the reply streams in.

@ProviderFor(AiChatNotifier)
final aiChatProvider = AiChatNotifierProvider._();

/// Chat transcript. The last message grows while the reply streams in.
final class AiChatNotifierProvider extends $NotifierProvider<AiChatNotifier, List<ChatMessage>> {
  /// Chat transcript. The last message grows while the reply streams in.
  AiChatNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiChatProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiChatNotifierHash();

  @$internal
  @override
  AiChatNotifier create() => AiChatNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChatMessage> value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<List<ChatMessage>>(value));
  }
}

String _$aiChatNotifierHash() => r'8fdb7fbeff921170dff542c1963c7ed9a93f77eb';

/// Chat transcript. The last message grows while the reply streams in.

abstract class _$AiChatNotifier extends $Notifier<List<ChatMessage>> {
  List<ChatMessage> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<ChatMessage>, List<ChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ChatMessage>, List<ChatMessage>>,
              List<ChatMessage>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
