// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auto-disposed: leaving the chat starts a new conversation next time.

@ProviderFor(aiChatService)
final aiChatServiceProvider = AiChatServiceProvider._();

/// Auto-disposed: leaving the chat starts a new conversation next time.

final class AiChatServiceProvider extends $FunctionalProvider<AiChatService, AiChatService, AiChatService>
    with $Provider<AiChatService> {
  /// Auto-disposed: leaving the chat starts a new conversation next time.
  AiChatServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiChatServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiChatServiceHash();

  @$internal
  @override
  $ProviderElement<AiChatService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AiChatService create(Ref ref) {
    return aiChatService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiChatService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AiChatService>(value));
  }
}

String _$aiChatServiceHash() => r'b9c36020dcdf1b348dd9e2175e245b9a0c4d3f6a';
