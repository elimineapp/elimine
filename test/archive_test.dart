import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/motion/motion.dart';
import 'package:elimine/app/motion/shared_axis.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/features/archive/archive_screen.dart';
import 'package:elimine/features/home/home_screen.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Lets database work started by the UI finish in real time, then settles.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  /// Home with "Kept" and "Old"; "Old" is archived when [archive] is set.
  Future<String> pumpHome(WidgetTester tester, {bool archive = true}) async {
    final old = (await tester.runAsync(() async {
      final substances = SubstanceService(db);
      Future<String> create(String name) => substances.create((
        name: name,
        unit: '',
        color: 'blue',
        icon: 'pill',
        doses: const [],
      ));
      await create('Kept');
      final old = await create('Old');
      await IntakeService(db).log(substanceId: old, amount: null);
      if (archive) await substances.archive(old);
      return old;
    }))!;

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/archive',
          pageBuilder: (_, state) =>
              SharedAxisPage(key: state.pageKey, child: const ArchiveScreen()),
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
    return old;
  }

  Future<void> openArchiveMenu(WidgetTester tester, String id) async {
    await tester.scrollUntilVisible(
      find.text('Archive (1)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Archive (1)'));
    await settle(tester);
    expect(find.text('1 entry'), findsOneWidget);
    await tester.tap(find.byKey(Key('archiveMenu-$id')));
    await tester.pumpAndSettle();
  }

  testWidgets('no archive row while nothing is archived', (tester) async {
    await pumpHome(tester, archive: false);
    expect(find.byKey(const Key('archiveEntry')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the archive comes forward as Home recedes', (tester) async {
    await pumpHome(tester);
    double scaleOf(Type screen) => tester
        .widget<ScaleTransition>(
          find
              .ancestor(
                of: find.byType(screen),
                matching: find.byType(ScaleTransition),
              )
              .first,
        )
        .scale
        .value;

    await tester.scrollUntilVisible(
      find.text('Archive (1)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Archive (1)'));
    await tester.pump();
    await tester.pump(Motion.medium * 0.5);

    expect(scaleOf(ArchiveScreen), inExclusiveRange(0.8, 1));
    expect(scaleOf(HomeScreen), greaterThan(1));

    await settle(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ArchiveScreen), findsNothing);
    expect(find.byType(HomeScreen).hitTestable(), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the back gesture scrubs the transition; cancelling keeps the '
      'archive', (tester) async {
    await pumpHome(tester);
    await tester.scrollUntilVisible(
      find.text('Archive (1)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Archive (1)'));
    await settle(tester);

    double archiveScale() => tester
        .widget<ScaleTransition>(
          find
              .ancestor(
                of: find.byType(ArchiveScreen),
                matching: find.byType(ScaleTransition),
              )
              .first,
        )
        .scale
        .value;
    Future<void> gesture(String method, [double progress = 0]) =>
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(method, <String, dynamic>{
              'touchOffset': <double>[5, 300],
              'x': 5 + 300 * progress,
              'y': 300.0,
              'progress': progress,
              'swipeEdge': 0,
            }),
          ),
          (_) {},
        );

    await gesture('startBackGesture');
    await gesture('updateBackGestureProgress', 0.5);
    await tester.pump();
    expect(archiveScale(), inExclusiveRange(0.8, 1));

    await gesture('cancelBackGesture');
    await tester.pumpAndSettle();
    expect(find.byType(ArchiveScreen), findsOneWidget);
    expect(archiveScale(), 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Restore puts the substance back on Home', (tester) async {
    final id = await pumpHome(tester);
    // Only its entry in "Recent": archived substances have no tile.
    expect(find.text('Old'), findsOneWidget);

    await openArchiveMenu(tester, id);
    await tester.tap(find.text('Restore'));
    await settle(tester);

    // The archive closes once empty; the tile is back.
    expect(find.byType(ArchiveScreen), findsNothing);
    expect(find.text('Old'), findsNWidgets(2));
    expect(find.byKey(const Key('archiveEntry')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Delete removes it after confirmation', (tester) async {
    final id = await pumpHome(tester);

    await openArchiveMenu(tester, id);
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.text('Delete Old?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmDelete')));
    await settle(tester);

    expect(find.byType(ArchiveScreen), findsNothing);
    expect(find.text('Old deleted'), findsOneWidget);
    final left = (await tester.runAsync(() => db.select(db.substances).get()))!;
    expect(left.map((s) => s.name), ['Kept']);
    await tester.pumpWidget(const SizedBox());
  });
}
