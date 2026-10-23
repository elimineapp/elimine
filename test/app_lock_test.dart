import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/features/lock/app_lock.dart';
import 'package:elimine/features/lock/pin_hash.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lock_fakes.dart';

void main() {
  late AppDatabase db;
  late DateTime now;
  late FakeBiometrics biometrics;
  late FakeRecentsWindow window;
  const text = (title: 'Unlock', reason: 'Unlock', cancel: 'Use PIN');

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    now = DateTime(2026, 10, 23, 20);
    biometrics = FakeBiometrics();
    window = FakeRecentsWindow();
  });

  tearDown(() => db.close());

  /// A fresh app start: reads the stored lock as `main` does.
  Future<ProviderContainer> start() async {
    final lock = await SettingsService(db).readLock();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
        initialLockProvider.overrideWithValue(lock),
        pinHasherProvider.overrideWithValue(fastPinHasher),
        biometricsProvider.overrideWithValue(biometrics),
        recentsWindowProvider.overrideWithValue(window),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// A started app with the lock on and PIN 2468, unlocked.
  Future<(ProviderContainer, AppLock)> withPin({
    Duration after = const Duration(minutes: 1),
  }) async {
    final container = await start();
    final lock = container.read(appLockProvider.notifier);
    await lock.setPin('2468');
    await lock.setLockAfter(after);
    return (container, lock);
  }

  test('without a PIN the app starts unlocked', () async {
    final container = await start();
    final state = container.read(appLockProvider);
    expect(state.enabled, isFalse);
    expect(state.locked, isFalse);
    expect(window.calls, isEmpty);
  });

  test('a cold start is locked and the right PIN unlocks', () async {
    await withPin();
    final container = await start();
    expect(container.read(appLockProvider).locked, isTrue);
    expect(window.calls.last, isTrue);

    final lock = container.read(appLockProvider.notifier);
    expect(await lock.unlockWithPin('1111'), PinCheck.wrong);
    expect(container.read(appLockProvider).locked, isTrue);
    expect(container.read(appLockProvider).failures, 1);

    expect(await lock.unlockWithPin('2468'), PinCheck.right);
    expect(container.read(appLockProvider).locked, isFalse);
    expect(container.read(appLockProvider).failures, 0);
  });

  test('turning the lock on does not lock and hides recent apps', () async {
    final (container, _) = await withPin();
    final state = container.read(appLockProvider);
    expect(state.enabled, isTrue);
    expect(state.locked, isFalse);
    expect(state.pinLength, 4);
    expect(window.calls, [true]);
  });

  group('when the app locks', () {
    test('a short absence keeps it open, a long one locks', () async {
      final (container, lock) = await withPin();
      lock.appHidden();
      now = now.add(const Duration(seconds: 20));
      lock.appShown();
      expect(container.read(appLockProvider).locked, isFalse);

      lock.appHidden();
      now = now.add(const Duration(minutes: 2));
      lock.appShown();
      expect(container.read(appLockProvider).locked, isTrue);
    });

    test('"Immediately" locks as soon as the app is hidden', () async {
      final (container, lock) = await withPin(after: Duration.zero);
      lock.appHidden();
      expect(container.read(appLockProvider).locked, isTrue);
      now = now.add(const Duration(seconds: 2));
      lock.appShown();
      expect(container.read(appLockProvider).locked, isTrue);
    });

    test('the app\'s own system dialogs do not count', () async {
      final (container, lock) = await withPin(after: Duration.zero);
      await lock.whileExternal(() async {
        lock.appHidden();
        now = now.add(const Duration(minutes: 3));
        lock.appShown();
      });
      expect(container.read(appLockProvider).locked, isFalse);

      lock.appHidden();
      expect(container.read(appLockProvider).locked, isTrue);
    });

    test('nothing happens while the lock is off', () async {
      final container = await start();
      final lock = container.read(appLockProvider.notifier);
      lock.appHidden();
      now = now.add(const Duration(hours: 1));
      lock.appShown();
      expect(container.read(appLockProvider).locked, isFalse);
    });
  });

  group('throttling', () {
    Future<void> fail(AppLock lock, int times) async {
      for (var i = 0; i < times; i++) {
        expect(await lock.unlockWithPin('0000'), PinCheck.wrong);
      }
    }

    test('the fifth wrong PIN blocks for 30 s, the sixth for 1 min', () async {
      await withPin();
      final container = await start();
      final lock = container.read(appLockProvider.notifier);
      await fail(lock, 4);
      expect(container.read(appLockProvider).blockedUntil, isNull);
      await fail(lock, 1);
      expect(
        container.read(appLockProvider).blockedUntil,
        now.add(const Duration(seconds: 30)),
      );
      // Even the right PIN is refused while blocked.
      expect(await lock.unlockWithPin('2468'), PinCheck.blocked);

      now = now.add(const Duration(seconds: 30));
      await fail(lock, 1);
      expect(
        container.read(appLockProvider).blockedUntil,
        now.add(const Duration(minutes: 1)),
      );
    });

    test('the wait stops growing at an hour', () async {
      await withPin();
      final container = await start();
      final lock = container.read(appLockProvider.notifier);
      for (var i = 0; i < 15; i++) {
        final until = container.read(appLockProvider).blockedUntil;
        if (until != null) now = until;
        await fail(lock, 1);
      }
      expect(
        container.read(appLockProvider).blockedUntil,
        now.add(const Duration(hours: 1)),
      );
    });

    test('a restart keeps the wait', () async {
      await withPin();
      final first = await start();
      await fail(first.read(appLockProvider.notifier), 5);
      first.dispose();

      now = now.add(const Duration(seconds: 10));
      final second = await start();
      final lock = second.read(appLockProvider.notifier);
      expect(second.read(appLockProvider).failures, 5);
      expect(await lock.unlockWithPin('2468'), PinCheck.blocked);
      now = now.add(const Duration(seconds: 20));
      expect(await lock.unlockWithPin('2468'), PinCheck.right);
    });

    test('biometrics unlock while blocked and reset the count', () async {
      final (_, setup) = await withPin();
      expect(await setup.enableBiometrics(text), isTrue);
      final container = await start();
      final lock = container.read(appLockProvider.notifier);
      await fail(lock, 5);
      expect(await lock.unlockWithBiometrics(text), isTrue);
      final state = container.read(appLockProvider);
      expect(state.locked, isFalse);
      expect(state.failures, 0);
      expect(state.blockedUntil, isNull);
      expect((await SettingsService(db).readLock()).failures, 0);
    });
  });

  group('settings', () {
    test('turning the lock off forgets everything about it', () async {
      final (container, lock) = await withPin(after: Duration.zero);
      await lock.enableBiometrics(text);
      await lock.disable();
      expect(container.read(appLockProvider).enabled, isFalse);
      final stored = await SettingsService(db).readLock();
      expect(stored.pin, isNull);
      expect(stored.biometric, isFalse);
      expect(stored.lockAfter, const Duration(minutes: 1));
      expect(window.calls, [true, false]);

      await lock.setPin('1357');
      expect(container.read(appLockProvider).lockAfter.inMinutes, 1);
      expect(container.read(appLockProvider).biometric, isFalse);
    });

    test('a new PIN replaces the old one', () async {
      final (container, lock) = await withPin();
      expect(await lock.checkPin('2468'), PinCheck.right);
      await lock.setPin('135790');
      expect(container.read(appLockProvider).pinLength, 6);
      expect(await lock.checkPin('2468'), PinCheck.wrong);
      expect(await lock.checkPin('135790'), PinCheck.right);
      // Changing the PIN keeps the lock on, so recent apps stay hidden.
      expect(window.calls, [true]);
    });

    test('a failed biometric check leaves biometric unlock off', () async {
      final (container, lock) = await withPin();
      biometrics.succeed = false;
      expect(await lock.enableBiometrics(text), isFalse);
      expect(container.read(appLockProvider).biometric, isFalse);
      expect((await SettingsService(db).readLock()).biometric, isFalse);

      biometrics.succeed = true;
      expect(await lock.enableBiometrics(text), isTrue);
      await lock.disableBiometrics();
      expect((await SettingsService(db).readLock()).biometric, isFalse);
    });

    test('an old hash is upgraded after a right PIN', () async {
      await withPin();
      final stored = await SettingsService(db).readLock();
      expect(stored.pin, startsWith(r'pbkdf2-sha256$1$'));
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
          initialLockProvider.overrideWithValue(stored),
          pinHasherProvider.overrideWithValue(
            const PinHasher(iterations: 2, inIsolate: false),
          ),
          biometricsProvider.overrideWithValue(biometrics),
          recentsWindowProvider.overrideWithValue(window),
        ],
      );
      addTearDown(container.dispose);
      final lock = container.read(appLockProvider.notifier);
      expect(await lock.unlockWithPin('2468'), PinCheck.right);
      final upgraded = (await SettingsService(db).readLock()).pin;
      expect(upgraded, startsWith(r'pbkdf2-sha256$2$'));
      expect(await lock.checkPin('2468'), PinCheck.right);
    });
  });

  group('erasing after a forgotten PIN', () {
    test('removes all data and the lock, keeps preferences', () async {
      final settings = SettingsService(db);
      await settings.setLocale(const Locale('ru'));
      await settings.setThemeMode(ThemeMode.dark);
      await settings.setWeekStart(DateTime.sunday);
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'cup',
        color: 'orange',
        icon: 'coffee',
        doses: [1],
      ));
      await IntakeService(db).log(substanceId: id, amount: 1);
      await withPin();

      final container = await start();
      await container.read(appLockProvider.notifier).eraseAll();

      expect(container.read(appLockProvider).enabled, isFalse);
      expect(container.read(appLockProvider).locked, isFalse);
      expect(await db.select(db.substances).get(), isEmpty);
      expect(await db.select(db.doses).get(), isEmpty);
      expect(await db.select(db.intakes).get(), isEmpty);
      expect((await settings.readLock()).pin, isNull);
      final preferences = await settings.readPreferences();
      expect(preferences.locale, const Locale('ru'));
      expect(preferences.themeMode, ThemeMode.dark);
      expect(await settings.watchWeekStart().first, DateTime.sunday);
      expect(window.calls.last, isFalse);
    });
  });
}
