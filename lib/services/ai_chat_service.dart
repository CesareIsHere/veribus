import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_chat_service.g.dart';

/// One Gemini conversation through Firebase AI Logic: no API key in the app,
/// calls are proxied by Firebase (enable App Check in production).
class AiChatService {
  AiChatService()
    : _chat = FirebaseAI.googleAI()
          .generativeModel(
            model: AppConfig.aiModel,
            systemInstruction: Content.system('You are a helpful assistant inside ${AppConfig.appName}. Be concise.'),
          )
          .startChat();

  final ChatSession _chat;

  /// Streams the reply in chunks; the conversation history is kept.
  Stream<String> send(String text) => _chat.sendMessageStream(Content.text(text)).map((r) => r.text ?? '');
}

/// Auto-disposed: leaving the chat starts a new conversation next time.
@riverpod
AiChatService aiChatService(Ref ref) => AiChatService();
