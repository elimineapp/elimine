import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/app/router.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/features/backup/settings_screen.dart';
import 'package:elimine/features/home/home_screen.dart';
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
}
