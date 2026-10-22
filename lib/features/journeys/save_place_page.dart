import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/providers/position_provider.dart';
import 'package:veribus/core/widgets/transit_map.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/journeys/place_search_page.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/models/journeys/place.dart';
import 'package:veribus/services/place_search_service.dart';
import 'package:veribus/styles/app_spacing.dart';
import 'package:veribus/styles/app_theme.dart';

/// What the page opens with: which place to save and, when the user already searched for it, where it is.
class SavePlaceArgs {
  const SavePlaceArgs({required this.type, this.place});

  final PlaceType type;
  final Place? place;
}

/// Home or work on the map: the pin stays in the middle and the map moves under it, the address under the pin is
/// read as it moves. Found first by address ("search") or placed by hand. Saved only on the phone. Pops with true
/// when saved.
class SavePlacePage extends ConsumerStatefulWidget {
  const SavePlacePage({this.args = const SavePlaceArgs(type: PlaceType.home), super.key});

  static const route = '/journeys/save-place';

  final SavePlaceArgs args;

  @override
  ConsumerState<SavePlacePage> createState() => _SavePlacePageState();
}

class _SavePlacePageState extends ConsumerState<SavePlacePage> {
  /// The address is asked when the map has been still this long: not once per frame of a drag.
  static const _still = Duration(milliseconds: 700);

  final _controller = MapController();
  Timer? _timer;
  late PlaceType _type = widget.args.type;
  late Place? _address = widget.args.place;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _moved(MapCamera camera, {required bool byUser}) {
    if (!byUser) return;
    _timer?.cancel();
    _timer = Timer(_still, () async {
      final found = await ref.read(placeSearchServiceProvider).reverse(camera.center);
      if (mounted) setState(() => _address = found);
    });
  }

  Future<void> _search() async {
    final result = await context.push<PlaceSearchResult>(
      PlaceSearchPage.route,
      extra: const PlaceSearchArgs(single: true),
    );
    final place = result?.to;
    if (place == null || !mounted) return;
    setState(() => _address = place);
    _controller.move(place.point, 18);
  }

  Future<void> _save() async {
    final point = _controller.camera.center;
    if (_type == PlaceType.home) {
      await ref.read(homePlaceProvider.notifier).set(point);
    } else {
      await ref.read(workPlaceProvider.notifier).set(point);
    }
    if (!mounted) return;
    context.showSnackBar(_type == PlaceType.home ? context.l10n.journeysHomeSaved : context.l10n.journeysWorkSaved);
    if (context.canPop()) context.pop(true);
  }

  Future<void> _remove() async {
    if (_type == PlaceType.home) {
      await ref.read(homePlaceProvider.notifier).clear();
    } else {
      await ref.read(workPlaceProvider.notifier).clear();
    }
    if (mounted && context.canPop()) context.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colors;
    final saved = _type == PlaceType.home ? ref.watch(homePlaceProvider) : ref.watch(workPlaceProvider);
    // Opens on the address found, else on the place saved, else on the user (the usual case: setting it while there).
    final start = widget.args.place?.point ?? saved ?? ref.watch(positionProvider).value ?? rome;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            // The map ends where the sheet begins, so the pin's tip is on the centre of the map: the place saved.
            child: Stack(
              children: [
                TransitMap(
                  controller: _controller,
                  center: start,
                  zoom: 17,
                  onMoved: _moved,
                  locateButton: false,
                  children: const [],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.xxxl + Spacing.s),
                        child: Icon(
                          Icons.location_on,
                          size: Spacing.xxxl + Spacing.s,
                          color: scheme.primary,
                          semanticLabel: l10n.journeysPinPlace,
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(context.pageMargin, Spacing.s, context.pageMargin, 0),
                    child: Row(
                      spacing: Spacing.m,
                      children: [
                        IconButton.filledTonal(
                          tooltip: l10n.close,
                          icon: const Icon(Icons.close),
                          onPressed: () => context.pop(false),
                        ),
                        Expanded(
                          child: Material(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(Spacing.xl),
                            clipBehavior: Clip.antiAlias,
                            elevation: 1,
                            child: ListTile(
                              leading: const Icon(Icons.search),
                              title: Text(l10n.journeysSearchAddress),
                              onTap: () => unawaited(_search()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: scheme.surface,
            elevation: 3,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.xl, Spacing.xl, Spacing.l),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Spacing.l,
                  children: [
                    Text(
                      _address?.name ?? l10n.journeysPinPlace,
                      style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (_address?.detail.isNotEmpty ?? false)
                      Text(
                        _address!.detail,
                        style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    Text(l10n.journeysSaveAs, style: context.textTheme.labelLarge),
                    Wrap(
                      spacing: Spacing.s,
                      children: [
                        ChoiceChip(
                          avatar: const Icon(Icons.home_outlined),
                          label: Text(l10n.journeysHomePlace),
                          selected: _type == PlaceType.home,
                          onSelected: (_) => setState(() => _type = PlaceType.home),
                        ),
                        ChoiceChip(
                          avatar: const Icon(Icons.work_outline),
                          label: Text(l10n.journeysWorkPlace),
                          selected: _type == PlaceType.work,
                          onSelected: (_) => setState(() => _type = PlaceType.work),
                        ),
                      ],
                    ),
                    Text(l10n.journeysSaveHint, style: context.textTheme.bodyMedium),
                    FilledButton(
                      onPressed: () => unawaited(_save()),
                      child: Text(_type == PlaceType.home ? l10n.journeysSaveHome : l10n.journeysSaveWork),
                    ),
                    if (saved != null)
                      TextButton.icon(
                        onPressed: () => unawaited(_remove()),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(_type == PlaceType.home ? l10n.journeysRemoveHome : l10n.journeysRemoveWork),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
