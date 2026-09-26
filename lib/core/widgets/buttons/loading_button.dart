import 'package:flutter/material.dart';

enum LoadingButtonStyle { filled, tonal, outlined, text }

/// M3 button that shows a progress indicator and ignores taps while
/// [onPressed] runs. Errors are left to the caller (`ExceptionHandler.handle`).
class LoadingButton extends StatefulWidget {
  const LoadingButton({
    required this.onPressed,
    required this.label,
    this.icon,
    this.style = LoadingButtonStyle.filled,
    super.key,
  });

  final Future<void> Function()? onPressed;
  final String label;
  final IconData? icon;
  final LoadingButtonStyle style;

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _loading = false;

  Future<void> _run() async {
    setState(() => _loading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed == null || _loading ? null : _run;
    // Same size as an 18dp button icon; inherits the button's foreground color.
    final icon = _loading
        ? Builder(
            builder: (context) => SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: IconTheme.of(context).color),
            ),
          )
        : (widget.icon == null ? null : Icon(widget.icon));
    final label = Text(widget.label);

    if (icon == null) {
      return switch (widget.style) {
        LoadingButtonStyle.filled => FilledButton(onPressed: onPressed, child: label),
        LoadingButtonStyle.tonal => FilledButton.tonal(onPressed: onPressed, child: label),
        LoadingButtonStyle.outlined => OutlinedButton(onPressed: onPressed, child: label),
        LoadingButtonStyle.text => TextButton(onPressed: onPressed, child: label),
      };
    }
    return switch (widget.style) {
      LoadingButtonStyle.filled => FilledButton.icon(onPressed: onPressed, icon: icon, label: label),
      LoadingButtonStyle.tonal => FilledButton.tonalIcon(onPressed: onPressed, icon: icon, label: label),
      LoadingButtonStyle.outlined => OutlinedButton.icon(onPressed: onPressed, icon: icon, label: label),
      LoadingButtonStyle.text => TextButton.icon(onPressed: onPressed, icon: icon, label: label),
    };
  }
}
