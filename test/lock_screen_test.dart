import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/app/router.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/features/analytics/analytics.dart';
import 'package:elimine/features/home/home_screen.dart';
import 'package:elimine/features/lock/lock_screen.dart';
import 'package:elimine/features/substance/substance_screen.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lock_fakes.dart';

void main() {
  late AppDatabase db;
  late DateTime now;
  late FakeBiometrics biometrics;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    now = DateTime(2026, 10, 23, 20);
    biometrics = FakeBiometrics();
  });

  tearDown(() => db.close());

  test('typed phrases ignore case, spaces and "ё"', () {
    expect(normalizePhrase(' erase   all '), normalizePhrase('ERASE ALL'));
    expect(normalizePhrase(' очистить  все'), normalizePhrase('ОЧИСТИТЬ ВСЁ'));
    expect(normalizePhrase('Очистить Всё'), normalizePhrase('ОЧИСТИТЬ ВСЁ'));
    expect(normalizePhrase('ERASE'), isNot(normalizePhrase('ERASE ALL')));
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  /// The app as `main` starts it: with the lock on (PIN 2468) unless
  /// [lockOn] is false, and a substance "Coffee" with one intake.
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    bool lockOn = true,
    bool biometric = false,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final lock = (await tester.runAsync(() async {
      final settings = SettingsService(db);
      final id = await SubstanceService(db).create((
        name: 'Coffee',
        unit: 'cup',
        color: 'orange',
        icon: 'coffee',
        doses: [1],
      ));
      await IntakeService(db).log(substanceId: id, amount: 1);
      if (lockOn) {
        await settings.setLockPin(await fastPinHasher.hash('2468'), 4);
        await settings.setLockBiometric(biometric);
      }
      return settings.readLock();
    }))!;
    final router = buildRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appVersionProvider.overrideWith((ref) async => '0.1.0'),
          clockProvider.overrideWithValue(() => now),
          initialLockProvider.overrideWithValue(lock),
          pinHasherProvider.overrideWithValue(fastPinHasher),
          biometricsProvider.overrideWithValue(biometrics),
          recentsWindowProvider.overrideWithValue(FakeRecentsWindow()),
        ],
        child: MaterialApp.router(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => LockLayer(
            backButtonDispatcher: router.backButtonDispatcher,
            onErased: () => router.go('/'),
            child: child!,
          ),
        ),
      ),
    );
    await settle(tester);
    return ProviderScope.containerOf(tester.element(find.byType(LockLayer)));
  }

  Future<void> enter(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.byKey(Key('pin-$d')));
      await tester.pump();
    }
    await settle(tester);
  }

  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  testWidgets('a cold start shows only the lock screen; the PIN opens Home', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    expect(find.text('Enter PIN'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Coffee'), findsNothing);

    await enter(tester, '2468');
    expect(container.read(appLockProvider).locked, isFalse);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Enter PIN'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('without the lock the app opens on Home', (tester) async {
    await pumpApp(tester, lockOn: false);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Enter PIN'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a wrong PIN says so and stays locked', (tester) async {
    await pumpApp(tester);
    await enter(tester, '1111');
    expect(find.text('Wrong PIN'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('after 5 wrong PINs the keypad waits with a countdown', (
    tester,
  ) async {
    await pumpApp(tester);
    for (var i = 0; i < 5; i++) {
      await enter(tester, '1111');
    }
    expect(find.text('Too many attempts. Try again in 0:30'), findsOneWidget);
    final key = tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const Key('pin-2')),
        matching: find.byType(TextButton),
      ),
    );
    expect(key.onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('biometric unlock opens the app without a tap', (tester) async {
    await pumpApp(tester, biometric: true);
    expect(biometrics.prompts, 1);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a cancelled prompt leaves the keypad, with a key to retry', (
    tester,
  ) async {
    biometrics.succeed = false;
    await pumpApp(tester, biometric: true);
    expect(find.text('Enter PIN'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pin-biometric')));
    await settle(tester);
    expect(biometrics.prompts, 2);
    await enter(tester, '2468');
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with biometrics removed from the device, only the PIN', (
    tester,
  ) async {
    biometrics.available = false;
    await pumpApp(tester, biometric: true);
    expect(biometrics.prompts, 0);
    expect(find.byKey(const Key('pin-biometric')), findsNothing);
    await enter(tester, '2468');
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('unlocking returns to the same tab and range', (tester) async {
    final container = await pumpApp(tester);
    await enter(tester, '2468');
    await tester.tap(tab('Analytics'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();

    final lock = container.read(appLockProvider.notifier);
    await tester.runAsync(() => lock.setLockAfter(Duration.zero));
    lock.appHidden();
    await tester.pumpAndSettle();
    expect(find.text('Enter PIN'), findsOneWidget);
    expect(find.text('Year'), findsNothing);

    await enter(tester, '2468');
    final range = tester.widget<SegmentedButton<AnalyticsRange>>(
      find.byType(SegmentedButton<AnalyticsRange>),
    );
    expect(range.selected, {AnalyticsRange.year});
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('nothing behind the lock reaches screen readers, open sheets '
      'included; back leaves the app and keeps them', (tester) async {
    final semantics = tester.ensureSemantics();
    final container = await pumpApp(tester);
    await enter(tester, '2468');
    await tester.tap(find.text('Coffee').first);
    await tester.pumpAndSettle();
    expect(find.byType(SubstanceScreen), findsOneWidget);

    final lock = container.read(appLockProvider.notifier);
    await tester.runAsync(() => lock.setLockAfter(Duration.zero));
    lock.appHidden();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Coffee')), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Enter PIN')), findsOneWidget);

    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(calls, contains('SystemNavigator.pop'));
    expect(container.read(appLockProvider).locked, isTrue);

    await enter(tester, '2468');
    expect(find.byType(SubstanceScreen), findsOneWidget);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  group('forgotten PIN', () {
    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('forgotPin')));
      await tester.pumpAndSettle();
    }

    bool eraseEnabled(WidgetTester tester) =>
        tester
            .widget<TextButton>(find.byKey(const Key('eraseAll')))
            .onPressed !=
        null;

    testWidgets('"Cancel" keeps everything', (tester) async {
      await pumpApp(tester);
      await openDialog(tester);
      expect(find.text('Erase all data?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Enter PIN'), findsOneWidget);
      expect(
        await tester.runAsync(() => db.select(db.substances).get()),
        hasLength(1),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Erase all" waits for the phrase', (tester) async {
      await pumpApp(tester);
      await openDialog(tester);
      expect(eraseEnabled(tester), isFalse);
      await tester.enterText(find.byKey(const Key('erasePhrase')), 'ERASE');
      await tester.pump();
      expect(eraseEnabled(tester), isFalse);
      await tester.enterText(
        find.byKey(const Key('erasePhrase')),
        'ОЧИСТИТЬ ВСЁ',
      );
      await tester.pump();
      expect(eraseEnabled(tester), isFalse);
      await tester.enterText(find.byKey(const Key('erasePhrase')), 'erase all');
      await tester.pump();
      expect(eraseEnabled(tester), isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('in Russian, the phrase typed casually works', (tester) async {
      await pumpApp(tester, locale: const Locale('ru'));
      await openDialog(tester);
      expect(find.text('Очистить все данные?'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('erasePhrase')),
        ' очистить  все',
      );
      await tester.pump();
      expect(eraseEnabled(tester), isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('erasing opens an empty Home with the lock off', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      await openDialog(tester);
      await tester.enterText(find.byKey(const Key('erasePhrase')), 'ERASE ALL');
      await tester.pump();
      await tester.tap(find.byKey(const Key('eraseAll')));
      await settle(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Coffee'), findsNothing);
      expect(container.read(appLockProvider).enabled, isFalse);
      expect(
        await tester.runAsync(() => db.select(db.substances).get()),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    });
  });
}
