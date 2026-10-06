import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/core/db/queries.dart';
import 'package:elimine/features/home/home_screen.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:elimine/widgets/intake_tile.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  Future<void> pumpHome(
    WidgetTester tester, {
    DateTime Function()? clock,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          if (clock != null) clockProvider.overrideWithValue(clock),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the header has no settings action', (tester) async {
    await pumpHome(tester);

    expect(find.byKey(const Key('settingsAction')), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.settings_outlined),
      ),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a tile shows the name without the unit', (tester) async {
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'amber',
        icon: 'coffee',
        doses: const [250],
      ));
      await IntakeService(db).log(substanceId: id, amount: 250);
    });

    await pumpHome(tester);

    expect(find.text('Coffee'), findsWidgets);
    expect(find.text('Coffee, mg'), findsNothing);
    expect(find.text('250 mg · just now'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a last intake without a dose shows only when it happened', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Tea',
        unit: '',
        color: 'green',
        icon: 'coffee',
        doses: const [],
      ));
      await IntakeService(db).log(
        substanceId: id,
        amount: null,
        takenAt: DateTime.now().subtract(const Duration(hours: 5, minutes: 12)),
      );
    });

    await pumpHome(tester);

    // The tile: name without a unit, then only the time since the intake.
    expect(find.text('Tea'), findsWidgets);
    expect(find.text('5 h 12 min ago'), findsOneWidget);
    // The "History" entry: no dose, and nothing in its place.
    expect(
      tester
          .widget<ListTile>(
            find.descendant(
              of: find.byType(IntakeTile),
              matching: find.byType(ListTile),
            ),
          )
          .trailing,
      isNull,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping a "History" entry opens its edit sheet', (tester) async {
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'amber',
        icon: 'coffee',
        doses: const [250],
      ));
      await IntakeService(db).log(substanceId: id, amount: 250);
    });

    await pumpHome(tester);
    await tester.ensureVisible(find.byType(IntakeTile));
    await tester.tap(find.byType(IntakeTile));
    await tester.pumpAndSettle();

    expect(find.text('Edit entry'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Coffee'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a tile marks the weeks the substance was taken in', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'orange',
        icon: 'coffee',
        doses: const [250],
      ));
      await IntakeService(db).log(substanceId: id, amount: 250);
    });

    await pumpHome(tester);

    final marks = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('weekStrip')),
            matching: find.byType(Container),
          ),
        )
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();
    expect(marks, hasLength(12));
    // Only this week, the last mark, is in the substance color.
    expect(marks.last, isNot(marks.first));
    expect(marks.take(11).toSet(), hasLength(1));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('marks get stronger with more intakes in a week', (tester) async {
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'orange',
        icon: 'coffee',
        doses: const [250],
      ));
      final now = DateTime.now();
      // Four this week, two the week before, one the week before that.
      for (final (daysAgo, times) in [(0, 4), (7, 2), (14, 1)]) {
        for (var i = 0; i < times; i++) {
          await IntakeService(db).log(
            substanceId: id,
            amount: 250,
            // Just after midnight, so no entry slips into another day.
            takenAt: DateTime(now.year, now.month, now.day - daysAgo, 0, i),
          );
        }
      }
    });

    await pumpHome(tester);

    final alphas = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('weekStrip')),
            matching: find.byType(Container),
          ),
        )
        .map((c) => (c.decoration! as BoxDecoration).color!.a)
        .toList();
    expect(alphas[9], lessThan(alphas[10]));
    expect(alphas[10], lessThan(alphas[11]));
    expect(alphas[11], 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a long name wraps onto two lines', (tester) async {
    const name = 'Acetylsalicylic acid, extended release, 100 mg tablets';
    await tester.runAsync(
      () => SubstanceService(db).create((
        name: name,
        unit: 'mg',
        color: 'blue',
        icon: 'pill',
        doses: const [],
      )),
    );

    await pumpHome(tester);

    final text = tester.widget<Text>(find.text(name));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.text(name)).height, greaterThan(30));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('on first launch the only item is "New substance"', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('New substance'), findsOneWidget);
    expect(find.byKey(const Key('weekStrip')), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  group('reordering', () {
    Future<Map<String, String>> fill(WidgetTester tester) async {
      final ids = <String, String>{};
      await tester.runAsync(() async {
        for (final name in ['Coffee', 'Melatonin', 'Ibuprofen']) {
          ids[name] = await SubstanceService(db).create((
            name: name,
            unit: '',
            color: 'green',
            icon: 'pill',
            doses: const [],
          ));
        }
      });
      return ids;
    }

    /// Tile names (and "New substance") from top to bottom on screen.
    List<String> onScreen(WidgetTester tester) {
      final rows = ['Coffee', 'Melatonin', 'Ibuprofen', 'New substance']
        ..sort(
          (a, b) => tester
              .getTopLeft(find.text(a))
              .dy
              .compareTo(tester.getTopLeft(find.text(b)).dy),
        );
      return rows;
    }

    Future<List<String>> stored(WidgetTester tester) async =>
        (await tester.runAsync(() => db.watchSubstancesWithLast().first))!
            .map((i) => i.substance.name)
            .toList();

    /// Long-presses [name] and drags it by [by] in small steps.
    Future<void> drag(WidgetTester tester, String name, Offset by) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(name)),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(by / 20);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
    }

    testWidgets('dragging the third tile above the first moves it', (
      tester,
    ) async {
      await fill(tester);
      await pumpHome(tester);

      final from = tester.getCenter(find.text('Ibuprofen')).dy;
      final to = tester.getTopLeft(find.text('Coffee')).dy;
      await drag(tester, 'Ibuprofen', Offset(0, to - from - 20));
      // Through the drop animation, before the database is read again.
      await tester.pump(const Duration(milliseconds: 500));
      expect(onScreen(tester), [
        'Ibuprofen',
        'Coffee',
        'Melatonin',
        'New substance',
      ]);

      await tester.pumpAndSettle();
      expect(onScreen(tester), [
        'Ibuprofen',
        'Coffee',
        'Melatonin',
        'New substance',
      ]);
      expect(await stored(tester), ['Ibuprofen', 'Coffee', 'Melatonin']);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a tile dragged below "New substance" lands above it', (
      tester,
    ) async {
      await fill(tester);
      await pumpHome(tester);

      await drag(tester, 'Coffee', const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(onScreen(tester), [
        'Melatonin',
        'Ibuprofen',
        'Coffee',
        'New substance',
      ]);
      expect(await stored(tester), ['Melatonin', 'Ibuprofen', 'Coffee']);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a screen reader moves a tile with "Move up" and "Move down"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await fill(tester);
      await pumpHome(tester);

      SemanticsNode tile(String name) => tester.getSemantics(
        find
            .ancestor(
              of: find.text(name),
              matching: find.byType(ReorderableDelayedDragStartListener),
            )
            .first,
      );
      Map<String, int> actions(String name) => {
        for (final id in tile(
          name,
        ).getSemanticsData().customSemanticsActionIds!)
          CustomSemanticsAction.getAction(id)!.label!: id,
      };

      expect(actions('Coffee'), isNot(contains('Move up')));
      expect(actions('Coffee'), contains('Move down'));
      expect(actions('Ibuprofen'), contains('Move up'));
      expect(actions('Ibuprofen'), isNot(contains('Move down')));

      final coffee = tile('Coffee');
      coffee.owner!.performAction(
        coffee.id,
        SemanticsAction.customAction,
        actions('Coffee')['Move down'],
      );
      await tester.pumpAndSettle();

      expect(onScreen(tester), [
        'Melatonin',
        'Coffee',
        'Ibuprofen',
        'New substance',
      ]);
      expect(await stored(tester), ['Melatonin', 'Coffee', 'Ibuprofen']);

      await tester.pumpWidget(const SizedBox());
      handle.dispose();
    });
  });

  testWidgets('the time since the last intake updates every minute', (
    tester,
  ) async {
    var now = DateTime(2026, 9, 29, 10);
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'amber',
        icon: 'coffee',
        doses: const [250],
      ));
      await IntakeService(db).log(
        substanceId: id,
        amount: 250,
        takenAt: now.subtract(const Duration(seconds: 30)),
      );
    });

    await pumpHome(tester, clock: () => now);
    expect(find.text('250 mg · just now'), findsOneWidget);

    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('250 mg · 1 min ago'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  group('History feed', () {
    /// "Coffee" with [count] intakes an hour apart; the newest is 1 mg, the
    /// oldest [count] mg. "Old" is archived when [archived] is set.
    Future<void> seed(
      WidgetTester tester,
      int count, {
      bool archived = false,
    }) async {
      await tester.runAsync(() async {
        final substances = SubstanceService(db);
        final id = await substances.create((
          name: 'Coffee',
          unit: 'mg',
          color: 'amber',
          icon: 'coffee',
          doses: const [],
        ));
        final now = DateTime.now();
        for (var i = 1; i <= count; i++) {
          await IntakeService(db).log(
            substanceId: id,
            amount: i.toDouble(),
            takenAt: now.subtract(Duration(hours: i)),
          );
        }
        if (archived) {
          await substances.archive(
            await substances.create((
              name: 'Old',
              unit: '',
              color: 'blue',
              icon: 'pill',
              doses: const [],
            )),
          );
        }
      });
    }

    ScrollPosition position(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;

    /// Drags Home by [dy] in steps, as a finger would.
    Future<void> drag(WidgetTester tester, double dy) async {
      const step = 400.0;
      for (var left = dy.abs(); left > 0; left -= step) {
        final move = left < step ? left : step;
        await tester.drag(
          find.byType(CustomScrollView),
          Offset(0, dy < 0 ? -move : move),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    double backToTopOpacity(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(const Key('backToTop')),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    testWidgets('loads older intakes while scrolling, without jumping', (
      tester,
    ) async {
      await seed(tester, 120);
      await pumpHome(tester);

      expect(find.text('History'), findsOneWidget);
      expect(find.text('1 mg'), findsOneWidget);
      expect(find.text('120 mg', skipOffstage: false), findsNothing);

      // Scroll until the feed stops growing: every intake gets loaded.
      var seen = 0;
      for (var i = 0; i < 40 && find.text('120 mg').evaluate().isEmpty; i++) {
        final before = position(tester).pixels;
        await drag(tester, -1200);
        final after = position(tester).pixels;
        // Loading a page never moves the feed back.
        expect(after, greaterThanOrEqualTo(before));
        seen = i;
      }
      expect(find.text('120 mg'), findsOneWidget, reason: 'after $seen drags');

      // An entry from a later page still opens its edit sheet.
      await tester.tap(find.text('120 mg'));
      await tester.pumpAndSettle();
      expect(find.text('Edit entry'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('an entry from a later page can be swiped away', (
      tester,
    ) async {
      await seed(tester, 120);
      await pumpHome(tester);
      for (var i = 0; i < 40 && find.text('100 mg').evaluate().isEmpty; i++) {
        await drag(tester, -800);
      }

      await tester.ensureVisible(find.text('100 mg'));
      await tester.pumpAndSettle();
      await tester.drag(find.text('100 mg'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      // The deletion is saved in real time.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      expect(find.text('100 mg'), findsNothing);
      expect(find.text('Entry deleted'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the archive row sits between "New substance" and "History"', (
      tester,
    ) async {
      await seed(tester, 120, archived: true);
      await pumpHome(tester);

      final archive = find.byKey(const Key('archiveEntry'));
      expect(archive.hitTestable(), findsOneWidget);
      final y = tester.getCenter(archive).dy;
      expect(tester.getCenter(find.text('New substance')).dy, lessThan(y));
      expect(tester.getCenter(find.text('History')).dy, greaterThan(y));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Back to top" shows when heading up from far down', (
      tester,
    ) async {
      await seed(tester, 120);
      await pumpHome(tester);
      final screen = position(tester).viewportDimension;

      expect(backToTopOpacity(tester), 0);

      // Down past twice the screen: still hidden while going down.
      await drag(tester, -3 * screen);
      expect(position(tester).pixels, greaterThan(2 * screen));
      expect(backToTopOpacity(tester), 0);

      // Up a little: it shows.
      await drag(tester, 100);
      expect(backToTopOpacity(tester), 1);

      // Down again: it hides.
      await drag(tester, -100);
      expect(backToTopOpacity(tester), 0);

      // Up again, then tap it: Home is back at the top.
      await drag(tester, 100);
      await tester.tap(find.byKey(const Key('backToTop')));
      await tester.pumpAndSettle();
      expect(position(tester).pixels, 0);
      expect(find.text('Coffee').hitTestable(), findsWidgets);
      expect(backToTopOpacity(tester), 0);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Back to top" does not show near the top', (tester) async {
      await seed(tester, 120);
      await pumpHome(tester);
      final screen = position(tester).viewportDimension;

      await drag(tester, -1.5 * screen);
      await drag(tester, 100);
      expect(backToTopOpacity(tester), 0);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with animations removed, "Back to top" jumps at once', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await seed(tester, 120);
      await pumpHome(tester);
      final screen = position(tester).viewportDimension;

      await drag(tester, -4 * screen);
      await drag(tester, 100);
      await tester.tap(find.byKey(const Key('backToTop')));
      await tester.pump();

      expect(position(tester).pixels, 0);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
