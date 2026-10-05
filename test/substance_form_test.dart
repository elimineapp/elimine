import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/app/router.dart';
import 'package:elimine/core/appearance.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/core/db/queries.dart';
import 'package:elimine/features/home/home_screen.dart';
import 'package:elimine/features/substance/substance_form_screen.dart';
import 'package:elimine/features/substance/substance_screen.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:elimine/widgets/substance_badge.dart';
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

    expect(
      find.descendant(
        of: find.byKey(const Key('unitField')),
        matching: find.text('Unit of measure'),
      ),
      findsOneWidget,
    );

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

  group('header badge', () {
    Future<void> pumpForm(WidgetTester tester, String location) async {
      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(
            path: '/substance/new',
            builder: (_, _) => const SubstanceFormScreen(),
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
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    SubstanceBadge badge(WidgetTester tester) =>
        tester.widget<SubstanceBadge>(find.byKey(const Key('formBadge')));

    testWidgets('editing shows the saved color and icon; picking a color '
        'changes it before saving', (tester) async {
      final id = (await tester.runAsync(
        () => SubstanceService(db).create((
          name: 'Coffee',
          unit: 'mg',
          color: 'green',
          icon: 'coffee',
          doses: const [],
        )),
      ))!;
      await pumpForm(tester, '/substance/$id/edit');

      expect(find.text('Edit substance'), findsOneWidget);
      expect((badge(tester).color, badge(tester).icon), ('green', 'coffee'));
      expect(badge(tester).filled, isTrue);

      await tester.scrollUntilVisible(
        find.byKey(const Key('color_red')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('color_red')));
      await tester.pump();

      expect(badge(tester).color, 'red');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a new substance shows the default color', (tester) async {
      await pumpForm(tester, '/substance/new');

      expect(find.text('New substance'), findsOneWidget);
      expect(badge(tester).color, substanceColors.keys.first);

      await tester.pumpWidget(const SizedBox());
    });
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

  group('from the app', () {
    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => SettingsService(db).setSheetExpanded());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Lets the database answer the form, which loads in real time.
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('saving a new substance opens its sheet over Home', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('New substance'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('nameField')), 'Tea');
      await tester.tap(find.byKey(const Key('saveButton')));
      await settle(tester);

      expect(find.byType(SubstanceFormScreen), findsNothing);
      expect(find.byType(SubstanceScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byKey(const Key('logButton')).hitTestable(), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SubstanceScreen), findsNothing);
      expect(find.text('Tea').hitTestable(), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('after saving, the form shrinks into the new sheet', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('New substance'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('nameField')), 'Tea');
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );

      final surface = find.byKey(const Key('sheetEntranceSurface'));
      final tops = <double>[];
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (surface.evaluate().isNotEmpty) {
          tops.add(tester.getTopLeft(surface).dy);
        }
      }
      await settle(tester);

      final sheet = tester.getTopLeft(
        find
            .descendant(
              of: find.byType(SubstanceScreen),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(tops.where((top) => top > 0 && top < sheet.dy), isNotEmpty);
      expect(find.byType(SubstanceFormScreen), findsNothing);
      expect(find.byKey(const Key('chartAndHistory')).hitTestable(), findsOne);

      await tester.pumpWidget(const SizedBox());
    });

    Future<void> openEditFromSheet(WidgetTester tester) async {
      await tester.runAsync(
        () => SubstanceService(db).create((
          name: 'Tea',
          unit: '',
          color: 'green',
          icon: 'leaf',
          doses: const [],
        )),
      );
      await pumpApp(tester);
      await tester.tap(find.text('Tea'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editSubstance')));
      await settle(tester);
    }

    testWidgets('archiving from the sheet returns to Home without it', (
      tester,
    ) async {
      await openEditFromSheet(tester);
      await tester.scrollUntilVisible(
        find.widgetWithText(OutlinedButton, 'Archive'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Archive'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );

      // First the edit screen shrinks back into the sheet, which is still
      // there once the edit screen is gone.
      bool? sheetAfterEdit;
      for (var i = 0; i < 60 && sheetAfterEdit == null; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (find.byType(SubstanceFormScreen).evaluate().isEmpty) {
          sheetAfterEdit = find.byType(SubstanceScreen).evaluate().isNotEmpty;
        }
      }
      expect(sheetAfterEdit, isTrue);
      await settle(tester);

      expect(find.byType(SubstanceFormScreen), findsNothing);
      expect(find.byType(SubstanceScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Tea'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('deleting from the sheet returns to Home without it', (
      tester,
    ) async {
      await openEditFromSheet(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('deleteButton')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('deleteButton')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('confirmDelete')));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );

      // The snackbar waits until the sheet has closed.
      bool? sheetWithSnackbar;
      for (var i = 0; i < 80 && sheetWithSnackbar == null; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (find.text('Tea deleted').evaluate().isNotEmpty) {
          sheetWithSnackbar = find
              .byType(SubstanceScreen)
              .evaluate()
              .isNotEmpty;
        }
      }
      expect(sheetWithSnackbar, isFalse);
      await settle(tester);

      expect(find.byType(SubstanceFormScreen), findsNothing);
      expect(find.byType(SubstanceScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Tea'), findsNothing);
      expect(find.text('Tea deleted'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
