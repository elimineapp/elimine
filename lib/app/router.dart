import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/analytics/analytics_screen.dart';
import '../features/archive/archive_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/home/home_screen.dart';
import '../features/substance/substance_form_screen.dart';
import '../features/substance/substance_screen.dart';
import 'motion/container_transform.dart';
import 'motion/fade_through_branches.dart';
import 'motion/shared_axis.dart';
import 'sheet_page.dart';
import 'shell.dart';

final router = buildRouter();

/// The surface a screen grows out of, when the caller passed one.
TransitionOrigin? _origin(GoRouterState state) => switch (state.extra) {
  final TransitionOrigin origin => origin,
  _ => null,
};

/// A new router; tests build their own so navigation state does not leak.
GoRouter buildRouter() {
  final root = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: root,
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(shell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            FadeThroughBranches(
              currentIndex: shell.currentIndex,
              children: children,
            ),
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
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
                // Under Home so it is always the page below, even after
                // `go`; on the root navigator so they cover the bottom
                // navigation. `new` is declared before `:id` so it is not
                // taken for an id.
                routes: [
                  GoRoute(
                    path: 'substance/new',
                    parentNavigatorKey: root,
                    pageBuilder: (context, state) => ContainerTransformPage(
                      key: state.pageKey,
                      origin: _origin(state),
                      child: const SubstanceFormScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'substance/:id',
                    parentNavigatorKey: root,
                    pageBuilder: (context, state) => SheetPage(
                      key: state.pageKey,
                      entrance: switch (state.extra) {
                        final SheetEntrance entrance => entrance,
                        _ => SheetEntrance.slide,
                      },
                      child: SubstanceScreen(
                        substanceId: state.pathParameters['id']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: root,
                        pageBuilder: (context, state) => ContainerTransformPage(
                          key: state.pageKey,
                          origin: _origin(state),
                          child: SubstanceFormScreen(
                            substanceId: state.pathParameters['id'],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
      // Outside the shell: covers the bottom navigation.
      GoRoute(
        path: '/archive',
        pageBuilder: (context, state) =>
            SharedAxisPage(key: state.pageKey, child: const ArchiveScreen()),
      ),
    ],
  );
}
