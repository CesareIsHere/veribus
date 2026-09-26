import 'package:flutter/widgets.dart';

/// Rebuilds the whole app from scratch (fresh ProviderScope).
/// `RestartWidget.restartApp(context)`
class RestartWidget extends StatefulWidget {
  const RestartWidget({required this.child, super.key});

  final Widget child;

  static void restartApp(BuildContext context) => context.findAncestorStateOfType<_RestartWidgetState>()?._restart();

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void _restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}
