import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/app/router.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/core/db/queries.dart';
import 'package:elimine/features/backup/settings_screen.dart';
import 'package:elimine/features/home/home_screen.dart';
import 'package:elimine/features/substance/substance_form_screen.dart';
import 'package:elimine/features/substance/substance_screen.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appVersionProvider.overrideWith((ref) async => '0.1.0'),
        ],
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

  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  testWidgets('the tabs are Settings, Home and Analytics; the app opens on '
      'Home', (tester) async {
    await pumpApp(tester);

    final labels = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((d) => d.label);
    expect(labels, ['Settings', 'Home', 'Analytics']);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Settings opens as a tab and keeps its scroll position', (
    tester,
  ) async {
    // Small enough for the Settings list to scroll.
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await tester.tap(tab('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    ScrollPosition position() => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          ),
        )
        .position;

    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pumpAndSettle();
    final offset = position().pixels;
    expect(offset, greaterThan(0));

    await tester.tap(tab('Home'));
    await tester.pumpAndSettle();
    await tester.tap(tab('Settings'));
    await tester.pumpAndSettle();

    expect(position().pixels, offset);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"New substance" opens the new substance screen', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('New substance'));
    await tester.pumpAndSettle();

    expect(find.byType(SubstanceFormScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  group('substance screen', () {
    late String id;

    setUp(() async {
      id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'orange',
        icon: 'coffee',
        doses: const [250],
      ));
    });

    /// Opens Coffee from Home on a phone-sized screen. The expand hint is
    /// off unless [hint] is set.
    Future<void> openCoffee(WidgetTester tester, {bool hint = false}) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      if (!hint) {
        await tester.runAsync(() => SettingsService(db).setSheetExpanded());
      }
      await pumpApp(tester);
      // The tile comes before any "Recent" entry.
      await tester.tap(find.text('Coffee').first);
      await tester.pumpAndSettle();
    }

    Finder visible(Finder finder) => finder.hitTestable();

    /// The edit form loads the substance from the database, which needs real
    /// time to answer.
    Future<void> settleForm(WidgetTester tester) async {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> back(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    Future<void> expand(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('chartAndHistory')));
      await tester.pumpAndSettle();
    }

    double sheetTop(WidgetTester tester) => tester
        .getTopLeft(
          find
              .descendant(
                of: find.byType(SubstanceScreen),
                matching: find.byType(Material),
              )
              .first,
        )
        .dy;

    testWidgets('opens collapsed over Home and covers the bottom bar', (
      tester,
    ) async {
      await openCoffee(tester);

      expect(find.byType(SubstanceScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(visible(find.byKey(const Key('logButton'))), findsOneWidget);
      expect(visible(find.byKey(const Key('chartAndHistory'))), findsOneWidget);
      expect(visible(find.text('History')), findsNothing);
      expect(visible(find.byType(NavigationBar)), findsNothing);

      await back(tester);
      expect(find.byType(SubstanceScreen), findsNothing);
      expect(visible(find.byType(NavigationBar)), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a tap on Home above the sheet closes it', (tester) async {
      await openCoffee(tester);
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();

      expect(find.byType(SubstanceScreen), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Chart and history" expands it, "Collapse" brings it back', (
      tester,
    ) async {
      await openCoffee(tester);
      final collapsedTop = sheetTop(tester);

      await expand(tester);
      expect(sheetTop(tester), lessThan(collapsedTop));
      expect(visible(find.byKey(const Key('collapseSheet'))), findsOneWidget);
      expect(visible(find.byKey(const Key('chartAndHistory'))), findsNothing);
      expect(visible(find.text('History')), findsOneWidget);

      await tester.tap(find.byKey(const Key('collapseSheet')));
      await tester.pumpAndSettle();
      expect(sheetTop(tester), collapsedTop);
      expect(visible(find.byKey(const Key('chartAndHistory'))), findsOneWidget);
      expect(find.byKey(const Key('collapseSheet')), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('dragging up expands it, dragging down closes it', (
      tester,
    ) async {
      await openCoffee(tester);
      final collapsedTop = sheetTop(tester);

      await tester.drag(
        find.byKey(const Key('logButton')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      expect(visible(find.byKey(const Key('collapseSheet'))), findsOneWidget);

      await tester.drag(find.text('Coffee').last, const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(sheetTop(tester), collapsedTop);

      await tester.drag(find.text('Coffee').last, const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(find.byType(SubstanceScreen), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('system back closes it when expanded too', (tester) async {
      await openCoffee(tester);
      await expand(tester);
      await back(tester);

      expect(find.byType(SubstanceScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the settings action opens the edit screen; back returns', (
      tester,
    ) async {
      await openCoffee(tester);
      await tester.tap(find.byKey(const Key('editSubstance')));
      await settleForm(tester);
      expect(find.byType(SubstanceFormScreen), findsOneWidget);

      await back(tester);
      expect(find.byType(SubstanceFormScreen), findsNothing);
      expect(visible(find.byKey(const Key('logButton'))), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Log" when collapsed closes it and reports on Home', (
      tester,
    ) async {
      await openCoffee(tester);
      await tester.tap(find.byKey(const Key('logButton')));
      await tester.pumpAndSettle();

      expect(find.byType(SubstanceScreen), findsNothing);
      expect(find.text('Logged 250 mg'), findsOneWidget);
      expect(find.text('250 mg · today'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(
        await tester.runAsync(() => db.watchIntakesFor(id).first),
        isEmpty,
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Log" when expanded stays and shows the entry on top', (
      tester,
    ) async {
      await tester.runAsync(
        () => IntakeService(db).log(
          substanceId: id,
          amount: 250,
          takenAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      );
      await openCoffee(tester);
      await expand(tester);
      await tester.tap(find.byKey(const Key('logButton')));
      await tester.pumpAndSettle();

      expect(visible(find.byKey(const Key('collapseSheet'))), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SubstanceScreen),
          matching: find.text('Logged 250 mg'),
        ),
        findsOneWidget,
      );
      final intakes = (await tester.runAsync(
        () => db.watchIntakesFor(id).first,
      ))!;
      expect(intakes, hasLength(2));

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(
        await tester.runAsync(() => db.watchIntakesFor(id).first),
        hasLength(1),
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('until it has been expanded, it hints by lifting once', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await pumpApp(tester);

      Future<List<double>> openAndTrack() async {
        await tester.tap(find.text('Coffee'));
        final tops = <double>[];
        for (var i = 0; i < 100; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          if (find.byType(SubstanceScreen).evaluate().isNotEmpty) {
            tops.add(sheetTop(tester));
          }
        }
        await tester.pumpAndSettle();
        return tops;
      }

      final first = await openAndTrack();
      final rest = sheetTop(tester);
      // Rises above its resting place after opening, then settles back.
      final lowestAfterOpen = first.indexWhere((t) => t <= rest);
      expect(
        first.skip(lowestAfterOpen).reduce((a, b) => a < b ? a : b),
        lessThan(rest - 10),
      );
      expect(first.last, rest);

      // Expanding once turns the hint off.
      await expand(tester);
      await back(tester);
      final second = await openAndTrack();
      expect(second.reduce((a, b) => a < b ? a : b), rest);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
