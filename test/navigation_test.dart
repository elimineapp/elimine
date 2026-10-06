import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/app/motion/fade_through_branches.dart';
import 'package:elimine/app/motion/motion.dart';
import 'package:elimine/app/router.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/core/db/queries.dart';
import 'package:elimine/features/analytics/analytics.dart';
import 'package:elimine/features/analytics/analytics_screen.dart';
import 'package:elimine/features/backup/settings_screen.dart';
import 'package:elimine/features/home/home_screen.dart';
import 'package:elimine/features/substance/substance_form_screen.dart';
import 'package:elimine/features/substance/substance_screen.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:elimine/widgets/intake_tile.dart';
import 'package:elimine/widgets/substance_badge.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
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

  group('reselecting Home', () {
    Future<void> seed(WidgetTester tester) => tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'amber',
        icon: 'coffee',
        doses: const [],
      ));
      final now = DateTime.now();
      for (var i = 1; i <= 60; i++) {
        await IntakeService(db).log(
          substanceId: id,
          amount: i.toDouble(),
          takenAt: now.subtract(Duration(hours: i)),
        );
      }
    });

    ScrollPosition home(WidgetTester tester) => tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(HomeScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;

    testWidgets('far down, scrolls Home to the top', (tester) async {
      await seed(tester);
      await pumpApp(tester);
      home(tester).jumpTo(3000);
      await tester.pumpAndSettle();

      await tester.tap(tab('Home'));
      await tester.pumpAndSettle();

      expect(home(tester).pixels, 0);
      expect(find.text('Coffee').hitTestable(), findsWidgets);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('at the top, changes nothing', (tester) async {
      await seed(tester);
      await pumpApp(tester);

      await tester.tap(tab('Home'));
      await tester.pumpAndSettle();

      expect(home(tester).pixels, 0);
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('coming from another tab keeps the scroll position', (
      tester,
    ) async {
      await seed(tester);
      await pumpApp(tester);
      home(tester).jumpTo(1500);
      await tester.pumpAndSettle();

      await tester.tap(tab('Analytics'));
      await tester.pumpAndSettle();
      await tester.tap(tab('Home'));
      await tester.pumpAndSettle();

      expect(home(tester).pixels, 1500);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('tab transition', () {
    /// The opacity and scale a tab is drawn with by the tab container.
    ({double opacity, double scale}) look(WidgetTester tester, Type screen) {
      final within = find.descendant(
        of: find.byType(FadeThroughBranches),
        matching: find.byWidgetPredicate(
          (w) => w is FadeTransition || w is ScaleTransition,
        ),
        skipOffstage: false,
      );
      final around = find
          .ancestor(
            of: find.byType(screen, skipOffstage: false),
            matching: within,
          )
          .evaluate()
          .map((e) => e.widget)
          .toList()
          .reversed;
      return (
        opacity: around.whereType<FadeTransition>().first.opacity.value,
        scale: around.whereType<ScaleTransition>().first.scale.value,
      );
    }

    testWidgets('fades through from Home to Analytics', (tester) async {
      await pumpApp(tester);
      await tester.tap(tab('Analytics'));
      await tester.pump();
      await tester.pump(Motion.medium * 0.6);

      final analytics = look(tester, AnalyticsScreen);
      expect(analytics.opacity, inExclusiveRange(0, 1));
      expect(analytics.scale, lessThan(1));
      expect(look(tester, HomeScreen).opacity, 0);

      await tester.pumpAndSettle();
      expect(look(tester, AnalyticsScreen), (opacity: 1.0, scale: 1.0));
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the selected tab tapped again does not transition', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(tab('Home'));
      await tester.pump();
      await tester.pump(Motion.medium * 0.5);

      expect(look(tester, HomeScreen), (opacity: 1.0, scale: 1.0));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Analytics keeps its range across the transition', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(tab('Analytics'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();
      await tester.tap(tab('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(tab('Analytics'));
      await tester.pumpAndSettle();

      final range = tester.widget<SegmentedButton<AnalyticsRange>>(
        find.byType(SegmentedButton<AnalyticsRange>),
      );
      expect(range.selected, {AnalyticsRange.year});

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with animations removed, cross-fades without scaling', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await pumpApp(tester);
      await tester.tap(tab('Analytics'));
      await tester.pump();
      // Flutter itself runs animations 20 times faster in this mode.
      await tester.pump(Motion.short * 0.05 * 0.5);

      final analytics = look(tester, AnalyticsScreen);
      expect(analytics.opacity, inExclusiveRange(0, 1));
      expect(analytics.scale, 1);

      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('"New substance" opens the new substance screen', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('New substance'));
    await tester.pumpAndSettle();

    expect(find.byType(SubstanceFormScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the new substance screen grows from its row and shrinks back '
      'into it', (tester) async {
    await pumpApp(tester);
    final row = tester.getRect(find.text('New substance'));
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    await tester.tap(find.text('New substance'));
    await tester.pump();
    await tester.pump(Motion.long * 0.5);
    final surface = tester.getRect(
      find
          .ancestor(
            of: find.byType(SubstanceFormScreen),
            matching: find.byType(ClipRRect),
          )
          .first,
    );
    expect(surface.intersect(row), row);
    expect(surface.height, lessThan(screenHeight));

    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SubstanceFormScreen), findsNothing);
    expect(find.text('New substance').hitTestable(), findsOneWidget);

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
      // The tile comes before any "History" entry.
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

    testWidgets('a tap opens a tile that has just been dragged', (
      tester,
    ) async {
      await tester.runAsync(
        () => SubstanceService(db).create((
          name: 'Tea',
          unit: '',
          color: 'green',
          icon: 'leaf',
          doses: const [],
        )),
      );
      await tester.runAsync(() => SettingsService(db).setSheetExpanded());
      await pumpApp(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Tea')),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      final by =
          tester.getTopLeft(find.text('Coffee')).dy -
          tester.getCenter(find.text('Tea')).dy -
          20;
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(Offset(0, by / 20));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Tea')).dy,
        lessThan(tester.getTopLeft(find.text('Coffee')).dy),
      );

      await tester.tap(find.text('Tea'));
      await tester.pumpAndSettle();

      // No clash with the lifted copy of the tile and its icon hero.
      expect(tester.takeException(), isNull);
      expect(find.byType(SubstanceScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SubstanceScreen),
          matching: find.text('Tea'),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
    });

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

    /// Opens Coffee frame by frame and checks the sheet already has its
    /// final height in the first frame it shows.
    Future<void> expectNoJump(
      WidgetTester tester, {
      double width = 1080,
    }) async {
      tester.view.physicalSize = Size(width, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => SettingsService(db).setSheetExpanded());
      await pumpApp(tester);
      final screenHeight = tester.view.physicalSize.height / 2.625;

      await tester.tap(find.text('Coffee').first);
      final surfaces = find.descendant(
        of: find.byType(SubstanceScreen),
        matching: find.byType(Material),
      );
      double? firstVisible;
      for (var i = 0; i < 60 && firstVisible == null; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (surfaces.evaluate().isEmpty) continue;
        if (sheetTop(tester) < screenHeight - 1) {
          firstVisible = tester.getSize(surfaces.first).height;
        }
      }
      await tester.pumpAndSettle();

      expect(firstVisible, isNotNull);
      expect(firstVisible, closeTo(tester.getSize(surfaces.first).height, 0.5));

      await tester.pumpWidget(const SizedBox());
    }

    testWidgets('rises at its final height', expectNoJump);

    testWidgets('rises at its final height with large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      // The test font's wide glyphs need a wider screen at this size.
      await expectNoJump(tester, width: 2400);
    });

    testWidgets('with animations removed, fades in without sliding', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => SettingsService(db).setSheetExpanded());
      await pumpApp(tester);

      await tester.tap(find.text('Coffee').first);
      final surfaces = find.descendant(
        of: find.byType(SubstanceScreen),
        matching: find.byType(Material),
      );
      final tops = <double>[];
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 2));
        if (surfaces.evaluate().isEmpty) continue;
        final route = ModalRoute.of(tester.element(surfaces.first))!;
        // Laid out but not shown yet while it measures itself.
        if (route.animation!.value > 0) tops.add(sheetTop(tester));
      }
      await tester.pumpAndSettle();

      expect(tops, isNotEmpty);
      final settled = sheetTop(tester);
      expect(tops, everyElement(closeTo(settled, 0.5)));

      await tester.pumpWidget(const SizedBox());
    });

    /// Filled badges drawn outside any [Hero]: the shuttles of icons in
    /// flight.
    Finder flyingBadges() => find.byElementPredicate(
      (e) =>
          e.widget is SubstanceBadge &&
          (e.widget as SubstanceBadge).filled &&
          e.findAncestorWidgetOfExactType<Hero>() == null,
    );

    testWidgets('the icon flies from the Home tile into the sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      // Coffee is also in "History", whose badge must not share the tag.
      await tester.runAsync(() async {
        await SettingsService(db).setSheetExpanded();
        await IntakeService(db).log(substanceId: id, amount: 250);
      });
      await pumpApp(tester);
      final from = tester.getCenter(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.byWidgetPredicate(
            (w) => w is SubstanceBadge && w.filled,
          ),
        ),
      );

      await tester.tap(find.text('Coffee').first);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(flyingBadges(), findsOneWidget);
      final mid = tester.getCenter(flyingBadges());

      await tester.pumpAndSettle();
      expect(flyingBadges(), findsNothing);
      final to = tester.getCenter(
        find.descendant(
          of: find.byType(SubstanceScreen),
          matching: find.byWidgetPredicate(
            (w) => w is SubstanceBadge && w.filled,
          ),
        ),
      );
      expect(mid.dy, inExclusiveRange(from.dy, to.dy));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('its scrim is labeled for screen readers', (tester) async {
      await openCoffee(tester);

      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.semanticsLabel, 'Scrim');
      expect(barrier.color, Colors.black54);

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

    /// How opaque the sheet's content is drawn while screens move above it.
    double sheetOpacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.byType(SubstanceScreen),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    /// The surface the edit screen grows on.
    Rect editSurface(WidgetTester tester) => tester.getRect(
      find
          .ancestor(
            of: find.byType(SubstanceFormScreen),
            matching: find.byType(ClipRRect),
          )
          .first,
    );

    testWidgets('the edit screen grows from the collapsed sheet and shrinks '
        'back into it', (tester) async {
      await openCoffee(tester);
      final top = sheetTop(tester);

      await tester.tap(find.byKey(const Key('editSubstance')));
      await tester.pump();
      await tester.pump(Motion.long * 0.5);
      expect(editSurface(tester).top, inExclusiveRange(0, top));
      expect(sheetOpacity(tester), lessThan(1));

      await settleForm(tester);
      await back(tester);
      expect(find.byType(SubstanceFormScreen), findsNothing);
      expect(sheetOpacity(tester), 1);
      expect(sheetTop(tester), top);
      expect(visible(find.byKey(const Key('chartAndHistory'))), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with animations removed, the edit screen fades in without '
        'growing or a flying icon', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await openCoffee(tester);

      await tester.tap(find.byKey(const Key('editSubstance')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 4));

      expect(find.byType(SubstanceFormScreen), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(SubstanceFormScreen),
          matching: find.byType(ClipRRect),
        ),
        findsNothing,
      );
      expect(flyingBadges(), findsNothing);

      await settleForm(tester);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('saving from the expanded screen returns to it expanded', (
      tester,
    ) async {
      await openCoffee(tester);
      await expand(tester);
      await tester.tap(find.byKey(const Key('editSubstance')));
      await settleForm(tester);

      await tester.tap(find.byKey(const Key('saveButton')));
      await settleForm(tester);

      expect(find.byType(SubstanceFormScreen), findsNothing);
      expect(visible(find.byKey(const Key('collapseSheet'))), findsOneWidget);
      expect(sheetOpacity(tester), 1);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Edit entry" over the sheet leaves it still', (tester) async {
      await tester.runAsync(
        () => IntakeService(db).log(substanceId: id, amount: 250),
      );
      await openCoffee(tester);
      await expand(tester);
      final entry = find.descendant(
        of: find.byType(SubstanceScreen),
        matching: find.byType(IntakeTile),
      );
      await tester.scrollUntilVisible(
        entry,
        200,
        scrollable: find
            .descendant(
              of: find.byType(SubstanceScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(entry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Edit entry'), findsOneWidget);
      expect(sheetOpacity(tester), 1);

      await tester.pumpAndSettle();
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
      expect(find.text('250 mg · just now'), findsOneWidget);

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
