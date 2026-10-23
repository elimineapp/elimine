import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/features/backup/backup_files.dart';
import 'package:elimine/features/backup/backup_format.dart';
import 'package:elimine/features/lock/app_lock.dart';
import 'package:elimine/features/settings/settings_screen.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lock_fakes.dart';

/// Stands in for the system dialogs: [toOpen] is what the user picks (null
/// cancels), [saveAccepted] whether they confirm saving.
class FakeBackupFiles implements BackupFiles {
  String? toOpen;
  bool saveAccepted = true;
  String? savedName;
  String? savedContent;

  /// Runs while the dialog is open, e.g. to send the app to the background.
  void Function()? whileOpen;

  @override
  Future<bool> save(String fileName, String content) async {
    whileOpen?.call();
    if (!saveAccepted) return false;
    savedName = fileName;
    savedContent = content;
    return true;
  }

  @override
  Future<String?> open() async => toOpen;
}

void main() {
  final now = DateTime(2026, 10, 4, 14);
  late AppDatabase db;
  late FakeBackupFiles files;
  late FakeBiometrics biometrics;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    files = FakeBackupFiles();
    biometrics = FakeBiometrics();
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

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));

  AppLock appLock(WidgetTester tester) =>
      container(tester).read(appLockProvider.notifier);

  AppLockState lockState(WidgetTester tester) =>
      container(tester).read(appLockProvider);

  /// [lockPin] turns the app lock on with that PIN before the screen opens,
  /// as if set earlier; the lock is then unlocked, as Settings is only
  /// reachable that way.
  Future<void> pumpSettings(WidgetTester tester, {String? lockPin}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final lock = (await tester.runAsync(() async {
      final settings = SettingsService(db);
      if (lockPin != null) {
        await settings.setLockPin(
          await fastPinHasher.hash(lockPin),
          lockPin.length,
        );
      }
      return settings.readLock();
    }))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          backupFilesProvider.overrideWithValue(files),
          appVersionProvider.overrideWith((ref) async => '0.1.0'),
          initialLockProvider.overrideWithValue(lock),
          pinHasherProvider.overrideWithValue(fastPinHasher),
          biometricsProvider.overrideWithValue(biometrics),
          recentsWindowProvider.overrideWithValue(FakeRecentsWindow()),
        ],
        // Follows the chosen language and theme like the app does; the test
        // device is English and light.
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            locale: ref.watch(localeProvider).value,
            themeMode: ref.watch(themeModeProvider).value ?? ThemeMode.system,
            darkTheme: ThemeData(brightness: Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(clock: () => now),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (lockPin != null) {
      await tester.runAsync(() => appLock(tester).unlockWithPin(lockPin));
      await tester.pumpAndSettle();
    }
  }

  Future<void> enter(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.byKey(Key('pin-$d')));
      await tester.pump();
    }
    await settle(tester);
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('pin-next')));
    await settle(tester);
  }

  bool switchOn(WidgetTester tester, String key) =>
      tester.widget<SwitchListTile>(find.byKey(Key(key))).value;

  Future<int> count(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.intakes).get()))!.length;

  String backupWith(int intakes) => encodeBackup([
    BackupSubstance(
      id: '01999b5e-7c2a-7d3e-9f10-2b4c6d8e0a11',
      name: 'Coffee',
      intakes: [
        for (var i = 0; i < intakes; i++)
          BackupIntake(
            id: '01999b5e-7c2a-7d3e-9f10-2b4c6d8e0b${i.toString().padLeft(2, '0')}',
            takenAt: DateTime.utc(2026, 9, 1 + i, 8),
            tzOffsetMin: 180,
          ),
      ],
    ),
  ], now: now);

  testWidgets('export saves a dated file and confirms', (tester) async {
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Tea',
        unit: '',
        color: 'aqua',
        icon: 'leaf',
        doses: const [],
      ));
      await IntakeService(db).log(substanceId: id, amount: null);
    });
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('export')));
    await settle(tester);

    expect(files.savedName, 'elimine-2026-10-04.json');
    final [tea] = decodeBackup(files.savedContent!, now: DateTime.now());
    expect((tea.name, tea.intakes.length), ('Tea', 1));
    expect(find.text('Data exported'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelling the save dialog says nothing', (tester) async {
    files.saveAccepted = false;
    await pumpSettings(tester);
    await tester.tap(find.byKey(const Key('export')));
    await settle(tester);
    expect(find.text('Data exported'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('import previews, then adds on confirm', (tester) async {
    files.toOpen = backupWith(3);
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('import')));
    await settle(tester);
    expect(
      find.text('Will be added: 1 substance and 3 entries.'),
      findsOneWidget,
    );
    expect(await count(tester), 0);

    await tester.tap(find.byKey(const Key('confirmImport')));
    await settle(tester);
    expect(await count(tester), 3);
    expect(find.text('Imported: 1 substance and 3 entries'), findsOneWidget);

    // The same file again: nothing new, nothing to confirm.
    await tester.tap(find.byKey(const Key('import')));
    await settle(tester);
    expect(
      find.text('Everything in this file is already here.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('confirmImport')), findsNothing);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(await count(tester), 3);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelling the preview writes nothing', (tester) async {
    files.toOpen = backupWith(2);
    await pumpSettings(tester);
    await tester.tap(find.byKey(const Key('import')));
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(await count(tester), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an invalid file shows where it is broken', (tester) async {
    files.toOpen = backupWith(1).replaceFirst('+03:00', '');
    await pumpSettings(tester);
    await tester.tap(find.byKey(const Key('import')));
    await settle(tester);

    expect(find.text("Can't import this file"), findsOneWidget);
    expect(
      find.textContaining('substances[0].intakes[0].takenAt'),
      findsOneWidget,
    );
    expect(await count(tester), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelling the file picker does nothing', (tester) async {
    await pumpSettings(tester);
    await tester.tap(find.byKey(const Key('import')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the last row shows the installed version', (tester) async {
    await pumpSettings(tester);
    final last = tester.widgetList<ListTile>(find.byType(ListTile)).last;
    expect(last.key, const Key('version'));
    expect(
      find.descendant(
        of: find.byKey(const Key('version')),
        matching: find.text('Version'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('version')),
        matching: find.text('0.1.0'),
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('week starts on Monday until Sunday is chosen', (tester) async {
    await pumpSettings(tester);
    final row = find.byKey(const Key('weekStart'));
    expect(
      find.descendant(of: row, matching: find.text('Monday')),
      findsOneWidget,
    );

    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('weekStart-${DateTime.sunday}')));
    await settle(tester);

    expect(
      find.descendant(of: row, matching: find.text('Sunday')),
      findsOneWidget,
    );
    final saved = await tester.runAsync(
      () => SettingsService(db).watchWeekStart().first,
    );
    expect(saved, DateTime.sunday);
    await tester.pumpWidget(const SizedBox());
  });

  Future<void> choose(WidgetTester tester, String row, String option) async {
    await tester.tap(find.byKey(Key(row)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await settle(tester);
  }

  Finder rowShows(String row, String text) =>
      find.descendant(of: find.byKey(Key(row)), matching: find.text(text));

  testWidgets('choosing Русский switches the screen to Russian at once', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(rowShows('language', 'System'), findsOneWidget);

    await choose(tester, 'language', 'Русский');
    expect(find.text('Настройки'), findsOneWidget);
    expect(rowShows('language', 'Русский'), findsOneWidget);
    expect(rowShows('theme', 'Системная'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language')));
    await tester.pumpAndSettle();
    final options = tester
        .widgetList<RadioListTile<int>>(find.byType(RadioListTile<int>))
        .map((t) => (t.title! as Text).data);
    expect(options, ['Системный', 'English', 'Русский']);
    await tester.tap(find.text('Системный').last);
    await settle(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(rowShows('language', 'System'), findsOneWidget);
    final saved = await tester.runAsync(
      () => SettingsService(db).watchLocale().first,
    );
    expect(saved, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('System language follows the device', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpSettings(tester);
    expect(rowShows('language', 'Системный'), findsOneWidget);

    await choose(tester, 'language', 'English');
    expect(rowShows('language', 'English'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the theme follows the device until Light or Dark is chosen', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness;
    await pumpSettings(tester);
    expect(rowShows('theme', 'System'), findsOneWidget);
    expect(brightness(), Brightness.dark);

    await choose(tester, 'theme', 'Light');
    expect(rowShows('theme', 'Light'), findsOneWidget);
    expect(brightness(), Brightness.light);

    await choose(tester, 'theme', 'Dark');
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);

    await choose(tester, 'theme', 'System');
    expect(brightness(), Brightness.light);
    final saved = await tester.runAsync(
      () => SettingsService(db).watchThemeMode().first,
    );
    expect(saved, ThemeMode.system);
    await tester.pumpWidget(const SizedBox());
  });

  group('Security', () {
    testWidgets('sits between General and Backup with only the switch, off', (
      tester,
    ) async {
      await pumpSettings(tester);
      final general = tester.getTopLeft(find.text('General')).dy;
      final security = tester.getTopLeft(find.text('Security')).dy;
      final backup = tester.getTopLeft(find.text('Backup')).dy;
      expect(general < security && security < backup, isTrue);
      expect(switchOn(tester, 'appLock'), isFalse);
      expect(find.byKey(const Key('biometricUnlock')), findsNothing);
      expect(find.byKey(const Key('lockAfter')), findsNothing);
      expect(find.byKey(const Key('changePin')), findsNothing);
    });

    testWidgets('turning the lock on chooses a PIN and shows its rows', (
      tester,
    ) async {
      await pumpSettings(tester);
      await tester.tap(find.byKey(const Key('appLock')));
      await settle(tester);
      expect(find.text('Choose a PIN'), findsOneWidget);
      await enter(tester, '2468');
      await tapNext(tester);
      await enter(tester, '2468');
      await tapNext(tester);

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(switchOn(tester, 'appLock'), isTrue);
      expect(lockState(tester).locked, isFalse);
      expect(switchOn(tester, 'biometricUnlock'), isFalse);
      expect(find.text('1 minute'), findsOneWidget);
      expect(find.byKey(const Key('changePin')), findsOneWidget);
    });

    testWidgets('going back from the PIN screen leaves the lock off', (
      tester,
    ) async {
      await pumpSettings(tester);
      await tester.tap(find.byKey(const Key('appLock')));
      await settle(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(switchOn(tester, 'appLock'), isFalse);
      expect(lockState(tester).enabled, isFalse);
    });

    testWidgets('without biometrics on the device, no biometric row', (
      tester,
    ) async {
      biometrics.available = false;
      await pumpSettings(tester, lockPin: '2468');
      expect(switchOn(tester, 'appLock'), isTrue);
      expect(find.byKey(const Key('biometricUnlock')), findsNothing);
      expect(find.byKey(const Key('lockAfter')), findsOneWidget);
    });

    testWidgets('turning the lock off asks for the PIN', (tester) async {
      await pumpSettings(tester, lockPin: '2468');
      await tester.tap(find.byKey(const Key('appLock')));
      await settle(tester);
      expect(find.text('Enter your current PIN'), findsOneWidget);
      await enter(tester, '1111');
      expect(find.text('Wrong PIN'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(switchOn(tester, 'appLock'), isTrue);

      await tester.tap(find.byKey(const Key('appLock')));
      await settle(tester);
      await enter(tester, '2468');
      expect(switchOn(tester, 'appLock'), isFalse);
      expect(find.byKey(const Key('lockAfter')), findsNothing);
      expect(
        (await tester.runAsync(() => SettingsService(db).readLock()))!.pin,
        isNull,
      );
    });

    testWidgets('changing the PIN asks for the current one first', (
      tester,
    ) async {
      await pumpSettings(tester, lockPin: '2468');
      await tester.tap(find.byKey(const Key('changePin')));
      await settle(tester);
      await enter(tester, '1111');
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Choose a PIN'), findsNothing);

      await tester.tap(find.byKey(const Key('changePin')));
      await settle(tester);
      await enter(tester, '2468');
      expect(find.text('Choose a PIN'), findsOneWidget);
      await enter(tester, '1357');
      await tapNext(tester);
      await enter(tester, '1357');
      await tapNext(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
      final lock = appLock(tester);
      expect(
        await tester.runAsync(() => lock.checkPin('1357')),
        PinCheck.right,
      );
      expect(
        await tester.runAsync(() => lock.checkPin('2468')),
        PinCheck.wrong,
      );
    });

    testWidgets('"Lock after" offers four choices', (tester) async {
      await pumpSettings(tester, lockPin: '2468');
      await tester.tap(find.byKey(const Key('lockAfter')));
      await tester.pumpAndSettle();
      for (final label in ['Immediately', '5 minutes', '15 minutes']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Immediately'));
      await settle(tester);
      expect(find.text('Immediately'), findsOneWidget);
      expect(lockState(tester).lockAfter, Duration.zero);
    });

    testWidgets('biometric unlock turns on only after a successful check', (
      tester,
    ) async {
      biometrics.succeed = false;
      await pumpSettings(tester, lockPin: '2468');
      await tester.tap(find.byKey(const Key('biometricUnlock')));
      await settle(tester);
      expect(switchOn(tester, 'biometricUnlock'), isFalse);

      biometrics.succeed = true;
      await tester.tap(find.byKey(const Key('biometricUnlock')));
      await settle(tester);
      expect(switchOn(tester, 'biometricUnlock'), isTrue);
      expect(biometrics.prompts, 2);
    });

    testWidgets('exporting does not lock, even at "Immediately"', (
      tester,
    ) async {
      await pumpSettings(tester, lockPin: '2468');
      await tester.runAsync(() => appLock(tester).setLockAfter(Duration.zero));
      files.whileOpen = () {
        appLock(tester).appHidden();
        appLock(tester).appShown();
      };
      await tester.tap(find.byKey(const Key('export')));
      await settle(tester);
      expect(lockState(tester).locked, isFalse);
      expect(find.text('Data exported'), findsOneWidget);

      // Leaving the app otherwise still locks.
      appLock(tester).appHidden();
      expect(lockState(tester).locked, isTrue);
    });
  });
}
