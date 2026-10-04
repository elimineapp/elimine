import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/features/archive/archive_screen.dart';
import 'package:elimine/features/home/home_screen.dart';
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
        GoRoute(path: '/archive', builder: (_, _) => const ArchiveScreen()),
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
