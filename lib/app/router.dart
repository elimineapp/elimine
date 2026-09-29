import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/substance/substance_form_screen.dart';
import '../features/substance/substance_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        // Declared before `:id` so "new" is not taken for an id.
        GoRoute(
          path: 'substance/new',
          builder: (context, state) => const SubstanceFormScreen(),
        ),
        GoRoute(
          path: 'substance/:id',
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
    ),
  ],
);
