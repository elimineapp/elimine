import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/core/db/queries.dart';
import 'package:elimine/features/substance/substance_form_screen.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() => db.close());

  testWidgets('saves a substance without a unit', (tester) async {
    final router = GoRouter(
      initialLocation: '/substance/new',
      routes: [
        GoRoute(
          path: '/substance/new',
          builder: (_, _) => const SubstanceFormScreen(),
        ),
        GoRoute(
          path: '/substance/:id',
          builder: (_, state) => Text('opened ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nameField')), 'Tea');
    await tester.enterText(find.byKey(const Key('doseField')), '2');
    await tester.tap(find.byKey(const Key('addDoseButton')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, '2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsNothing);
    final saved = (await tester.runAsync(
      () => db.watchSubstancesWithLast().first,
    ))!.single.substance;
    expect((saved.name, saved.unit), ('Tea', ''));
    expect(find.text('opened ${saved.id}'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
