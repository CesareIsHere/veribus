import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/core/widgets/states/offline_banner.dart'; // feature:connectivity
import 'package:emiliano_cesare_flutter_template/styles/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef ShellDestination = ({IconData icon, IconData selectedIcon, String label});

/// M3 adaptive navigation by window size class: navigation bar (compact),
/// rail (medium, expanded), extended rail (large). Tabs keep their state.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, required this.destinations, super.key});

  final StatefulNavigationShell shell;
  final List<ShellDestination> destinations;

  /// Tapping the current tab again pops it to its first page.
  void _go(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final size = context.windowSize;
    final body = Column(
      children: [
        if (Features.connectivity) const OfflineBanner(), // feature:connectivity
        Expanded(child: shell),
      ],
    );

    if (size == WindowSize.compact) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _go,
          destinations: [
            for (final d in destinations)
              NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
          ],
        ),
      );
    }

    final extended = size == WindowSize.large;
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: extended,
              labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
