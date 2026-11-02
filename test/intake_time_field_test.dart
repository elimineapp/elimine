import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/widgets/intake_time_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Taps [chip] with the clock at [now] and returns the time it picks.
  Future<DateTime?> pick(WidgetTester tester, DateTime now, String chip) async {
    DateTime? picked;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: IntakeTimeField(
            value: null,
            clock: () => now,
            onChanged: (at) => picked = at,
          ),
        ),
      ),
    );
    await tester.tap(find.text(chip));
    return picked;
  }

  // Shortly after midnight following a 23-hour day, as after the switch to
  // summer time in zones that have one (e.g. Europe/Berlin on 29 March
  // 2026), 24 hours back is two calendar days back.
  final afterShortDay = DateTime(2026, 3, 30, 0, 30);

  testWidgets('"Yesterday" is the previous calendar day', (tester) async {
    expect(
      await pick(tester, afterShortDay, 'Yesterday'),
      DateTime(2026, 3, 29, 0, 30),
    );
  });

  testWidgets('"Day before" is two calendar days back', (tester) async {
    expect(
      await pick(tester, afterShortDay, 'Day before'),
      DateTime(2026, 3, 28, 0, 30),
    );
  });
}
