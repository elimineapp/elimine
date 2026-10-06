import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../l10n/app_localizations.dart';

/// Bottom navigation between the three top-level tabs. Each tab keeps its own
/// navigation stack and scroll position. Reselecting "Home" scrolls it back
/// to the top.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// Index of the "Home" destination.
  static const _home = 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) {
          if (i == _home && i == shell.currentIndex) {
            ref.read(homeScrollToTopProvider.notifier).request();
          }
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.settingsTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l.navAnalytics,
          ),
        ],
      ),
    );
  }
}
