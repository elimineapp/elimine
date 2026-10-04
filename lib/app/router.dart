import 'package:go_router/go_router.dart';

import '../features/analytics/analytics_screen.dart';
import '../features/archive/archive_screen.dart';
import '../features/backup/settings_screen.dart';
import '../features/home/home_screen.dart';
import '../features/substance/substance_form_screen.dart';
import '../features/substance/substance_screen.dart';
import 'shell.dart';

final router = buildRouter();

/// A new router; tests build their own so navigation state does not leak.
GoRouter buildRouter() => GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      // Home sits in the middle, the easiest slot to reach; the app still
      // opens on it because the initial location is `/`.
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
      ],
    ),
    // Outside the shell: these screens cover the bottom navigation.
    GoRoute(
      path: '/archive',
      builder: (context, state) => const ArchiveScreen(),
    ),
    // `new` is declared before `:id` so it is not taken for an id.
    GoRoute(
      path: '/substance/new',
      builder: (context, state) => const SubstanceFormScreen(),
    ),
    GoRoute(
      path: '/substance/:id',
      builder: (context, state) =>
          SubstanceScreen(substanceId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) =>
              SubstanceFormScreen(substanceId: state.pathParameters['id']),
        ),
      ],
    ),
  ],
);
