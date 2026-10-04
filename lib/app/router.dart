import 'package:go_router/go_router.dart';

import '../features/analytics/analytics_screen.dart';
import '../features/archive/archive_screen.dart';
import '../features/home/home_screen.dart';
import '../features/substance/substance_form_screen.dart';
import '../features/substance/substance_screen.dart';
import 'shell.dart';

final router = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
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
