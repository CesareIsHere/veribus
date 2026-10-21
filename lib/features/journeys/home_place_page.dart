import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/providers/position_provider.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Where home is: the pin stays in the middle and the map moves under it (the map's own button brings it to the
/// user). A create/edit screen: full-screen dialog, close + Save. Home is saved only on the phone.
class HomePlacePage extends ConsumerStatefulWidget {
  const HomePlacePage({super.key});

  static const route = '/journeys/home-place';

  @override
  ConsumerState<HomePlacePage> createState() => _HomePlacePageState();
}

class _HomePlacePageState extends ConsumerState<HomePlacePage> {
  final _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(homePlaceProvider.notifier).set(_controller.camera.center);
    if (!mounted) return;
    context
      ..showSnackBar(context.l10n.journeysHomeSaved)
      ..pop();
  }

  Future<void> _remove() async {
    await ref.read(homePlaceProvider.notifier).clear();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final home = ref.watch(homePlaceProvider);
    // Opens on home when there is one, else on the user (the usual case: setting it while at home).
    final start = home ?? ref.watch(positionProvider).value ?? rome;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: l10n.close, icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: Text(l10n.journeysHomeTitle),
        actions: [TextButton(onPressed: () => unawaited(_save()), child: Text(l10n.save))],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.pageMargin, Spacing.s, context.pageMargin, Spacing.m),
            child: Text(l10n.journeysHomeHint, style: context.textTheme.bodyMedium),
          ),
          Expanded(
            child: Stack(
              children: [
                TransitMap(controller: _controller, center: start, zoom: 17, children: const []),
                // The pin's tip on the centre of the map.
                IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.xxxl),
                      child: Icon(
                        Icons.location_on,
                        size: Spacing.xxxl,
                        color: context.colors.primary,
                        semanticLabel: l10n.journeysHomeTitle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (home != null)
            Padding(
              padding: EdgeInsets.all(context.pageMargin),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => unawaited(_remove()),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.journeysRemoveHome),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
