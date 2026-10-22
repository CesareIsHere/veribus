import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/providers/network_provider.dart';
import 'package:veribus/core/widgets/section_header.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/features/journeys/save_place_page.dart';
import 'package:veribus/models/journeys/place.dart';
import 'package:veribus/models/transit/network.dart';
import 'package:veribus/styles/app_spacing.dart';

/// Which end of the journey the search fills first.
enum PlaceSearchField { from, to }

/// What the search page brings back: where from (null is the user's position) and where to.
typedef PlaceSearchResult = ({Place? from, Place? to});

/// What the search page opens with. [single] searches one place only (home, work) and brings it back as the
/// destination.
class PlaceSearchArgs {
  const PlaceSearchArgs({this.from, this.to, this.field = PlaceSearchField.to, this.single = false});

  final Place? from;
  final Place? to;
  final PlaceSearchField field;
  final bool single;
}

/// Where from and where to, searched while typing: addresses and places by name, and the stops of the network.
/// Before typing: the user's position, home, work and the recent places. Pops with the [PlaceSearchResult].
class PlaceSearchPage extends ConsumerStatefulWidget {
  const PlaceSearchPage({this.args = const PlaceSearchArgs(), super.key});

  static const route = '/journeys/place';

  final PlaceSearchArgs args;

  @override
  ConsumerState<PlaceSearchPage> createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends ConsumerState<PlaceSearchPage> {
  /// Fewer letters than this find half of Rome.
  static const _minLength = 3;

  /// The search waits for a pause in the typing: one request per word, not per letter.
  static const _debounce = Duration(milliseconds: 400);

  final _fromField = TextEditingController();
  final _toField = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();
  Timer? _timer;
  late Place? _from = widget.args.from;
  late Place? _to = widget.args.to;
  late PlaceSearchField _active = widget.args.field;
  String _query = '';

  bool get _single => widget.args.single;

  TextEditingController get _activeField => _active == PlaceSearchField.from ? _fromField : _toField;

  @override
  void initState() {
    super.initState();
    // The chosen places show their names; the field being searched starts empty, for typing.
    _fromField.text = _from?.name ?? '';
    _toField.text = _to?.name ?? '';
    _activeField.clear();
    _fromFocus.addListener(() => _focused(PlaceSearchField.from, _fromFocus));
    _toFocus.addListener(() => _focused(PlaceSearchField.to, _toFocus));
  }

  void _focused(PlaceSearchField field, FocusNode node) {
    if (!node.hasFocus) return;
    setState(() {
      _active = field;
      _query = _activeField.text.trim();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fromField.dispose();
    _toField.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => setState(() => _query = text.trim()));
  }

  void _done() => context.pop<PlaceSearchResult>((from: _from, to: _to));

  /// The user's position is the start: the field says so and is left to be typed over.
  void _useMyPosition() {
    setState(() {
      _from = null;
      _fromField.clear();
      _query = '';
    });
    _toFocus.requestFocus();
  }

  Future<void> _choose(Place place) async {
    if (!place.isSaved) await ref.read(recentPlacesProvider.notifier).add(place);
    if (!mounted) return;
    if (_single) {
      context.pop<PlaceSearchResult>((from: null, to: place));
      return;
    }
    if (_active == PlaceSearchField.from) {
      setState(() {
        _from = place;
        _fromField.text = place.name;
        _query = '';
      });
      if (_to != null) {
        _done();
      } else {
        _toFocus.requestFocus();
      }
      return;
    }
    setState(() {
      _to = place;
      _toField.text = place.name;
    });
    _done();
  }

  /// Saved places that are not set yet are set on the map first.
  Future<void> _chooseSaved(PlaceType type) async {
    final home = ref.read(homePlaceProvider);
    final work = ref.read(workPlaceProvider);
    final point = type == PlaceType.home ? home : work;
    final l10n = context.l10n;
    if (point != null) {
      await _choose(
        Place(name: type == PlaceType.home ? l10n.journeysHomePlace : l10n.journeysWorkPlace, point: point, type: type),
      );
      return;
    }
    final saved = await context.push<bool>(SavePlacePage.route, extra: SavePlaceArgs(type: type));
    if (saved ?? false) await _chooseSaved(type);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colors;
    final searching = _query.length >= _minLength;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(Spacing.xs, Spacing.xs, context.pageMargin - Spacing.xs, Spacing.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.xs,
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Material(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(Spacing.xl),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.xs),
                        child: Column(
                          children: [
                            if (!_single) ...[
                              _field(
                                context,
                                controller: _fromField,
                                focus: _fromFocus,
                                field: PlaceSearchField.from,
                                label: l10n.journeysFromLabel,
                                hint: _from == null ? l10n.journeysYourPosition : _from!.name,
                                icon: Icon(Icons.trip_origin, size: Spacing.l, color: scheme.primary),
                              ),
                              Divider(height: 1, color: scheme.outlineVariant),
                            ],
                            _field(
                              context,
                              controller: _toField,
                              focus: _toFocus,
                              field: PlaceSearchField.to,
                              label: _single ? null : l10n.journeysToLabel,
                              hint: _single ? l10n.journeysSearchHint : (_to?.name ?? l10n.journeysWhereTo),
                              icon: Icon(Icons.place, size: Spacing.l + Spacing.xs, color: scheme.error),
                              autofocus: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: searching ? _results(context) : _start(context)),
          ],
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required FocusNode focus,
    required PlaceSearchField field,
    required String hint,
    required Widget icon,
    String? label,
    bool autofocus = false,
  }) {
    final active = _active == field;
    return Row(
      spacing: Spacing.m,
      children: [
        icon,
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focus,
            autofocus: autofocus && active,
            textInputAction: TextInputAction.search,
            style: context.textTheme.bodyLarge?.copyWith(fontWeight: active ? FontWeight.w700 : null),
            decoration: InputDecoration(
              labelText: label,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onChanged: _onChanged,
            onSubmitted: (text) {
              _timer?.cancel();
              setState(() => _query = text.trim());
            },
          ),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty || !active
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: context.l10n.clear,
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _timer?.cancel();
                    controller.clear();
                    setState(() => _query = '');
                  },
                ),
        ),
      ],
    );
  }

  /// Before typing: the user's position for the start, home and work, the recent places.
  Widget _start(BuildContext context) {
    final l10n = context.l10n;
    final home = ref.watch(homePlaceProvider);
    final work = ref.watch(workPlaceProvider);
    final recent = ref.watch(recentPlacesProvider);
    return ListView(
      padding: context.listPadding(),
      children: [
        if (!_single && _active == PlaceSearchField.from)
          ListTile(
            leading: const Icon(Icons.my_location),
            title: Text(l10n.journeysYourPosition),
            onTap: _useMyPosition,
          ),
        SectionHeader(l10n.journeysSavedSection),
        ListTile(
          leading: Icon(home == null ? Icons.add_home_outlined : Icons.home_outlined),
          title: Text(home == null ? l10n.journeysSetHome : l10n.journeysHomePlace),
          onTap: () => unawaited(_chooseSaved(PlaceType.home)),
        ),
        ListTile(
          leading: Icon(work == null ? Icons.add_business_outlined : Icons.work_outline),
          title: Text(work == null ? l10n.journeysSetWork : l10n.journeysWorkPlace),
          onTap: () => unawaited(_chooseSaved(PlaceType.work)),
        ),
        if (recent.isNotEmpty) SectionHeader(l10n.journeysRecent),
        for (final place in recent) _PlaceTile(place: place, onTap: () => unawaited(_choose(place))),
      ],
    );
  }

  Widget _results(BuildContext context) {
    final l10n = context.l10n;
    final network = ref.watch(networkProvider).value;
    final found = network?.search(_query, max: 5).stops ?? const <Stop>[];
    final stops = [
      for (final s in found)
        Place(
          name: s.name,
          detail: s.lineIds.map((id) => network?.lines[id]?.name ?? id).take(6).join(' · '),
          point: s.position,
          type: PlaceType.stop,
        ),
    ];
    final places = ref.watch(placeSearchProvider(_query));
    return ListView(
      padding: context.listPadding(),
      children: [
        ...switch (places) {
          AsyncValue(:final error?) when stops.isEmpty => [
            SizedBox(
              height: 320,
              child: MessageView.error(context, error, onRetry: () => ref.invalidate(placeSearchProvider(_query))),
            ),
          ],
          AsyncValue(:final value?) when value.isEmpty && stops.isEmpty => [
            SizedBox(
              height: 320,
              child: MessageView(icon: Icons.search_off, title: l10n.journeysSearchNone),
            ),
          ],
          AsyncValue(:final value?) => [
            if (value.isNotEmpty) SectionHeader(l10n.journeysPlacesSection),
            for (final place in value) _PlaceTile(place: place, onTap: () => unawaited(_choose(place))),
          ],
          _ => [const LinearProgressIndicator()],
        },
        if (stops.isNotEmpty) SectionHeader(l10n.journeysStopsSection),
        for (final stop in stops) _PlaceTile(place: stop, onTap: () => unawaited(_choose(stop))),
      ],
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurfaceVariant,
        child: Icon(switch (place.type) {
          PlaceType.stop => Icons.directions_bus_outlined,
          PlaceType.home => Icons.home_outlined,
          PlaceType.work => Icons.work_outline,
          PlaceType.place => Icons.place_outlined,
        }),
      ),
      title: Text(place.name),
      subtitle: place.detail.isEmpty ? null : Text(place.detail, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
