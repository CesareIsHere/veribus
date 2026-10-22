import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veribus/core/widgets/section_header.dart';
import 'package:veribus/core/widgets/states/message_view.dart';
import 'package:veribus/extensions/build_context_extensions.dart';
import 'package:veribus/features/journeys/home_place_page.dart';
import 'package:veribus/features/journeys/providers/journeys_providers.dart';
import 'package:veribus/models/journeys/place.dart';
import 'package:veribus/styles/app_spacing.dart';

/// What a place is searched for: where to go (home and the recent places come first) or where home is.
enum PlaceSearchFor { destination, home }

/// An address or a place by name, searched while typing. Pops with the chosen [Place].
class PlaceSearchPage extends ConsumerStatefulWidget {
  const PlaceSearchPage({this.purpose = PlaceSearchFor.destination, super.key});

  static const route = '/journeys/place';

  final PlaceSearchFor purpose;

  @override
  ConsumerState<PlaceSearchPage> createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends ConsumerState<PlaceSearchPage> {
  /// Fewer letters than this find half of Rome.
  static const _minLength = 3;

  /// The search waits for a pause in the typing: one request per word, not per letter.
  static const _debounce = Duration(milliseconds: 400);

  final _field = TextEditingController();
  Timer? _timer;
  String _query = '';

  @override
  void dispose() {
    _timer?.cancel();
    _field.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => setState(() => _query = text.trim()));
  }

  void _clear() {
    _timer?.cancel();
    _field.clear();
    setState(() => _query = '');
  }

  Future<void> _choose(Place place) async {
    if (widget.purpose == PlaceSearchFor.destination) await ref.read(recentPlacesProvider.notifier).add(place);
    if (mounted) context.pop(place);
  }

  Future<void> _setHome() async {
    await context.push(HomePlacePage.route);
    final home = ref.read(homePlaceProvider);
    if (home != null && mounted) context.pop(Place(name: context.l10n.journeysHomePlace, point: home, isHome: true));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _field,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(hintText: l10n.journeysSearchHint, border: InputBorder.none),
          onChanged: _onChanged,
          onSubmitted: (text) {
            _timer?.cancel();
            setState(() => _query = text.trim());
          },
        ),
        actions: [
          ListenableBuilder(
            listenable: _field,
            builder: (context, _) => _field.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(tooltip: l10n.clear, icon: const Icon(Icons.close), onPressed: _clear),
          ),
        ],
      ),
      body: _query.length < _minLength ? _start(context) : _results(context),
    );
  }

  /// Before typing: home and the recent places when choosing where to go.
  Widget _start(BuildContext context) {
    final l10n = context.l10n;
    if (widget.purpose == PlaceSearchFor.home) {
      return MessageView(icon: Icons.search, title: l10n.journeysSearchEmpty);
    }
    final home = ref.watch(homePlaceProvider);
    final recent = ref.watch(recentPlacesProvider);
    return ListView(
      padding: context.listPadding(),
      children: [
        if (home != null)
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(l10n.journeysHomePlace),
            onTap: () => unawaited(_choose(Place(name: l10n.journeysHomePlace, point: home, isHome: true))),
          )
        else
          ListTile(
            leading: const Icon(Icons.add_home_outlined),
            title: Text(l10n.journeysSetHome),
            onTap: () => unawaited(_setHome()),
          ),
        if (recent.isNotEmpty) SectionHeader(l10n.journeysRecent),
        for (final place in recent)
          _PlaceTile(place: place, icon: Icons.history, onTap: () => unawaited(_choose(place))),
      ],
    );
  }

  Widget _results(BuildContext context) {
    final l10n = context.l10n;
    return switch (ref.watch(placeSearchProvider(_query))) {
      AsyncValue(:final error?) => MessageView.error(
        context,
        error,
        onRetry: () => ref.invalidate(placeSearchProvider(_query)),
      ),
      AsyncValue(value: final places?) when places.isEmpty => MessageView(
        icon: Icons.search_off,
        title: l10n.journeysSearchNone,
      ),
      AsyncValue(value: final places?) => ListView(
        padding: context.listPadding(),
        children: [
          for (final place in places)
            _PlaceTile(place: place, icon: Icons.place_outlined, onTap: () => unawaited(_choose(place))),
        ],
      ),
      _ => const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator()),
    };
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.icon, required this.onTap});

  final Place place;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(place.name),
    subtitle: place.detail.isEmpty ? null : Text(place.detail),
    onTap: onTap,
  );
}
