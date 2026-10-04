import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/core/db/queries.dart';
import 'package:elimine/features/substance/substance_form_screen.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/substance_service.dart';
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

  group('deleting from the edit screen', () {
    late String id;

    /// Lets database work started by the UI finish in real time (the edit
    /// form shows a spinner until its substance loads), then settles.
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openEdit(WidgetTester tester) async {
      id = (await tester.runAsync(() async {
        final id = await SubstanceService(db).create((
          name: 'Test',
          unit: 'mg',
          color: 'red',
          icon: 'pill',
          doses: const [5],
        ));
        for (var i = 0; i < 3; i++) {
          await IntakeService(db).log(substanceId: id, amount: 5);
        }
        return id;
      }))!;
      final router = GoRouter(
        initialLocation: '/substance/$id/edit',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
          GoRoute(
            path: '/substance/:id/edit',
            builder: (_, state) =>
                SubstanceFormScreen(substanceId: state.pathParameters['id']),
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
      await settle(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('deleteButton')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('deleteButton')));
      await settle(tester);
      expect(find.text('Delete Test?'), findsOneWidget);
      expect(
        find.text(
          'All 3 of its entries will be deleted too. '
          'This cannot be undone.',
        ),
        findsOneWidget,
      );
    }

    testWidgets('confirming removes it with its entries', (tester) async {
      await openEdit(tester);
      await tester.tap(find.byKey(const Key('confirmDelete')));
      await settle(tester);

      expect(find.text('home'), findsOneWidget);
      expect(find.text('Test deleted'), findsOneWidget);
      final left = (await tester.runAsync(
        () async => (
          await db.select(db.substances).get(),
          await db.select(db.intakes).get(),
        ),
      ))!;
      expect(left.$1, isEmpty);
      expect(left.$2, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('cancelling keeps everything', (tester) async {
      await openEdit(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsNothing);
      final count = (await tester.runAsync(() => db.countIntakes(id)))!;
      expect(count, 3);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
