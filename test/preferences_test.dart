import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/app.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/services/settings_service.dart';
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

  test('language and theme providers follow what is stored', () async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final locale = container.listen(localeProvider, (_, _) {});
    final theme = container.listen(themeModeProvider, (_, _) {});
    expect(await container.read(localeProvider.future), isNull);
    expect(await container.read(themeModeProvider.future), ThemeMode.system);

    final settings = container.read(settingsServiceProvider);
    await settings.setLocale(const Locale('ru'));
    await settings.setThemeMode(ThemeMode.dark);
    await pumpEventQueue();
    expect(locale.read().value, const Locale('ru'));
    expect(theme.read().value, ThemeMode.dark);
  });

  testWidgets('the first frame already uses the stored language and theme', (
    tester,
  ) async {
    final settings = SettingsService(db);
    await tester.runAsync(() async {
      await settings.setLocale(const Locale('ru'));
      await settings.setThemeMode(ThemeMode.dark);
    });
    final initial = await tester.runAsync(settings.readPreferences);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          initialPreferencesProvider.overrideWithValue(initial!),
        ],
        child: const ElimineApp(),
      ),
    );
    void expectRussianAndDark() {
      final context = tester.element(find.byType(NavigationBar));
      expect(Localizations.localeOf(context), const Locale('ru'));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(find.text('Главная'), findsOneWidget);
    }

    expectRussianAndDark();

    // Once the streams emit, they agree with what was read.
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expectRussianAndDark();

    await tester.pumpWidget(const SizedBox());
  });
}
