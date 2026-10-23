import 'package:elimine/features/lock/pin_pad.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<PinController> pump(
    WidgetTester tester, {
    int? length,
    ValueChanged<String>? onComplete,
    VoidCallback? onBiometric,
  }) async {
    final controller = PinController();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: PinPad(
              controller: controller,
              length: length,
              onComplete: onComplete,
              onBiometric: onBiometric,
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  Future<void> enter(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.byKey(Key('pin-$d')));
      await tester.pump();
    }
  }

  int dots(WidgetTester tester) =>
      tester.widget<Row>(find.byKey(const Key('pin-dots'))).children.length;

  testWidgets('taps fill the dots and delete clears them', (tester) async {
    final controller = await pump(tester);
    expect(dots(tester), 4);
    await enter(tester, '24680');
    expect(controller.value, '24680');
    expect(dots(tester), 5);
    await tester.tap(find.byKey(const Key('pin-delete')));
    await tester.pump();
    expect(controller.value, '2468');
    expect(dots(tester), 4);
  });

  testWidgets('choosing a PIN stops at 8 digits', (tester) async {
    final controller = await pump(tester);
    await enter(tester, '1234567890');
    expect(controller.value, '12345678');
  });

  testWidgets('completes at the stored length', (tester) async {
    String? completed;
    final controller = await pump(
      tester,
      length: 6,
      onComplete: (pin) => completed = pin,
    );
    expect(dots(tester), 6);
    await enter(tester, '13579');
    expect(completed, isNull);
    await enter(tester, '1');
    expect(completed, '135791');
    await enter(tester, '2');
    expect(controller.value, '135791');
  });

  testWidgets('keys and dots are labelled for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, onBiometric: () {});
    expect(find.bySemanticsLabel('7'), findsOneWidget);
    expect(find.bySemanticsLabel('Delete digit'), findsOneWidget);
    expect(find.bySemanticsLabel('Use biometrics'), findsOneWidget);
    expect(find.bySemanticsLabel('No digits entered'), findsOneWidget);
    await enter(tester, '24');
    expect(find.bySemanticsLabel('2 digits entered'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('no biometric key unless asked for', (tester) async {
    await pump(tester);
    expect(find.byKey(const Key('pin-biometric')), findsNothing);
  });
}
