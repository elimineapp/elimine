import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/features/lock/pin_screens.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lock_fakes.dart';

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

  /// A button that runs [open] and keeps its result in [results].
  Future<List<Object?>> pump(
    WidgetTester tester,
    Future<Object?> Function(BuildContext) open, {
    LockSettings? lock,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final results = <Object?>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          pinHasherProvider.overrideWithValue(fastPinHasher),
          biometricsProvider.overrideWithValue(FakeBiometrics()),
          recentsWindowProvider.overrideWithValue(FakeRecentsWindow()),
          if (lock != null) initialLockProvider.overrideWithValue(lock),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(await open(context)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  Future<void> enter(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.byKey(Key('pin-$d')));
      await tester.pump();
    }
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('pin-next')));
    await tester.pumpAndSettle();
  }

  group('choosing a PIN', () {
    testWidgets('matching entries return the PIN', (tester) async {
      final results = await pump(
        tester,
        (context) => choosePin(context, warn: true),
      );
      expect(find.text('Choose a PIN'), findsOneWidget);
      expect(find.byKey(const Key('pin-setup-warning')), findsOneWidget);
      final keypad = tester.getCenter(find.byKey(const Key('pin-5')));
      await enter(tester, '2468');
      expect(find.text('Next'), findsOneWidget);
      await next(tester);
      expect(find.text('Confirm the PIN'), findsOneWidget);
      // The keypad does not move between the steps.
      expect(find.byKey(const Key('pin-setup-warning')), findsOneWidget);
      expect(tester.getCenter(find.byKey(const Key('pin-5'))), keypad);
      await enter(tester, '2468');
      expect(find.text('Done'), findsOneWidget);
      await next(tester);
      expect(results, ['2468']);
      expect(find.text('Choose a PIN'), findsNothing);
    });

    testWidgets('different entries start over', (tester) async {
      final results = await pump(
        tester,
        (context) => choosePin(context, warn: true),
      );
      await enter(tester, '2468');
      await next(tester);
      await enter(tester, '2469');
      await next(tester);
      expect(find.text('Choose a PIN'), findsOneWidget);
      expect(
        find.text('The PINs do not match. Choose a PIN again.'),
        findsOneWidget,
      );
      expect(results, isEmpty);
    });

    testWidgets('"Next" waits for 4 digits', (tester) async {
      await pump(tester, (context) => choosePin(context, warn: false));
      expect(find.byKey(const Key('pin-setup-warning')), findsNothing);
      await enter(tester, '246');
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('pin-next')),
      );
      expect(button.onPressed, isNull);
      await enter(tester, '8');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('pin-next')))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('going back returns nothing', (tester) async {
      final results = await pump(
        tester,
        (context) => choosePin(context, warn: true),
      );
      await enter(tester, '2468');
      await next(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(results, [null]);
    });
  });

  group('confirming the current PIN', () {
    Future<LockSettings> stored() async {
      final settings = SettingsService(db);
      await settings.setLockPin(await fastPinHasher.hash('2468'), 4);
      return settings.readLock();
    }

    testWidgets('the right PIN returns true', (tester) async {
      final lock = (await tester.runAsync(stored))!;
      final results = await pump(tester, verifyPin, lock: lock);
      expect(find.text('Enter your current PIN'), findsOneWidget);
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(
        tester.getCenter(find.byKey(const Key('pin-5'))).dx,
        closeTo(width / 2, 1),
      );
      await enter(tester, '2468');
      await tester.pumpAndSettle();
      expect(results, [true]);
    });

    testWidgets('a wrong PIN stays and says so', (tester) async {
      final lock = (await tester.runAsync(stored))!;
      final results = await pump(tester, verifyPin, lock: lock);
      await enter(tester, '1111');
      await tester.pumpAndSettle();
      expect(find.text('Wrong PIN'), findsOneWidget);
      expect(results, isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(results, [false]);
    });
  });
}
