import 'package:emiliano_cesare_flutter_template/services/ai_chat_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_chat_notifier.g.dart';

typedef ChatMessage = ({bool fromUser, String text});

/// Chat transcript. The last message grows while the reply streams in.
@riverpod
class AiChatNotifier extends _$AiChatNotifier {
  @override
  List<ChatMessage> build() {
    // Keeps the conversation (service) alive as long as this transcript.
    ref.watch(aiChatServiceProvider);
    return const [];
  }

  Future<void> send(String text) async {
    state = [...state, (fromUser: true, text: text), (fromUser: false, text: '')];
    final reply = StringBuffer();
    try {
      await for (final chunk in ref.read(aiChatServiceProvider).send(text)) {
        reply.write(chunk);
        if (!ref.mounted) return;
        state = [...state.sublist(0, state.length - 1), (fromUser: false, text: reply.toString())];
      }
    } on Object {
      if (ref.mounted && reply.isEmpty) state = state.sublist(0, state.length - 1);
      rethrow;
    }
  }
}
