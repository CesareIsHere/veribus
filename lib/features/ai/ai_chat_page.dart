import 'package:emiliano_cesare_flutter_template/core/utils/exception_handler.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/states/message_view.dart';
import 'package:emiliano_cesare_flutter_template/extensions/build_context_extensions.dart';
import 'package:emiliano_cesare_flutter_template/features/ai/providers/ai_chat_notifier.dart';
import 'package:emiliano_cesare_flutter_template/styles/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  static const route = '/assistant';

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestion]) async {
    final text = (suggestion ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() => _sending = true);
    await ExceptionHandler.handle(context, () => ref.read(aiChatProvider.notifier).send(text));
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final messages = ref.watch(aiChatProvider);
    final suggestions = [l10n.assistantSuggestion1, l10n.assistantSuggestion2, l10n.assistantSuggestion3];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assistant)),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? MessageView(
                    icon: Icons.auto_awesome,
                    title: l10n.assistantEmpty,
                    description: l10n.assistantDisclaimer,
                    action: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: Spacing.s,
                      runSpacing: Spacing.s,
                      children: [for (final s in suggestions) ActionChip(label: Text(s), onPressed: () => _send(s))],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: context.pagePadding(),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _Bubble(messages[messages.length - 1 - i]),
                  ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(context.pageMargin, Spacing.m, Spacing.s, Spacing.m),
              child: Row(
                spacing: Spacing.s,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(hintText: l10n.assistantHint),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: l10n.send,
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.message);

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final fromUser = message.fromUser;
    return Align(
      alignment: fromUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.m),
        constraints: const BoxConstraints(maxWidth: ContentWidth.form),
        decoration: BoxDecoration(
          color: fromUser ? context.colors.primaryContainer : context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(Spacing.l),
        ),
        child: message.text.isEmpty
            ? const SizedBox.square(dimension: Spacing.l, child: CircularProgressIndicator(strokeWidth: 2))
            : SelectableText(
                message.text,
                style: TextStyle(color: fromUser ? context.colors.onPrimaryContainer : context.colors.onSurface),
              ),
      ),
    );
  }
}
