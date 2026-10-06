import 'package:elimine/core/l10n/format.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru'));
  final now = DateTime(2026, 9, 29, 10);

  // Moments before [now], built on the calendar so months stay exact.
  final cases = <DateTime>[
    now.subtract(const Duration(seconds: 40)),
    now.subtract(const Duration(minutes: 12)),
    now.subtract(const Duration(hours: 5, minutes: 12)),
    now.subtract(const Duration(hours: 5, seconds: 30)),
    now.subtract(const Duration(days: 3, hours: 5)),
    now.subtract(const Duration(days: 3, minutes: 20)),
    now.subtract(const Duration(days: 23, hours: 4)),
    DateTime(2026, 5, 17, 10),
    DateTime(2024, 10, 24, 10),
    DateTime(2014, 6, 29, 10),
  ];

  test('elapsed time in English', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(cases.map((at) => en.elapsed(elapsedBetween(at, now))), [
      'just now',
      '12 min ago',
      '5 h 12 min ago',
      '5 h ago',
      '3 d 5 h ago',
      '3 days ago',
      '23 days ago',
      '4 mo 12 d ago',
      '1 year 11 mo ago',
      '12 years ago',
    ]);
  });

  test('elapsed time in Russian uses plural forms', () async {
    final ru = await AppLocalizations.delegate.load(const Locale('ru'));
    expect(cases.map((at) => ru.elapsed(elapsedBetween(at, now))), [
      'только что',
      '12 мин назад',
      '5 ч 12 мин назад',
      '5 ч назад',
      '3 дн. 5 ч назад',
      '3 дня назад',
      '23 дня назад',
      '4 мес. 12 дн. назад',
      '1 год 11 мес. назад',
      '12 лет назад',
    ]);
    expect(
      ru.elapsed(elapsedBetween(DateTime(2021, 9, 1), now)),
      '5 лет назад',
    );
    expect(
      ru.elapsed(elapsedBetween(DateTime(2024, 6, 29, 10), now)),
      '2 года 3 мес. назад',
    );
  });

  group('step boundaries', () {
    Elapsed split(Duration ago) => elapsedBetween(now.subtract(ago), now);

    test('switch at a minute, an hour, a day and a week', () {
      expect(split(const Duration(seconds: 59)).step, ElapsedStep.justNow);
      expect(split(const Duration(minutes: 1)).step, ElapsedStep.minutes);
      expect(split(const Duration(minutes: 59)).step, ElapsedStep.minutes);
      expect(split(const Duration(hours: 1)).step, ElapsedStep.hours);
      expect(
        split(const Duration(hours: 23, minutes: 59)).step,
        ElapsedStep.hours,
      );
      expect(split(const Duration(days: 1)).step, ElapsedStep.daysHours);
      expect(
        split(const Duration(days: 6, hours: 23)).step,
        ElapsedStep.daysHours,
      );
      expect(split(const Duration(days: 7)), (
        step: ElapsedStep.days,
        first: 7,
        second: 0,
      ));
    });

    test('switch at a month, a year and ten years', () {
      expect(
        elapsedBetween(DateTime(2026, 8, 29, 10, 1), now).step,
        ElapsedStep.days,
      );
      expect(elapsedBetween(DateTime(2026, 8, 29, 10), now), (
        step: ElapsedStep.monthsDays,
        first: 1,
        second: 0,
      ));
      expect(
        elapsedBetween(DateTime(2025, 9, 29, 10, 1), now).step,
        ElapsedStep.monthsDays,
      );
      expect(
        elapsedBetween(DateTime(2025, 9, 29, 10), now).step,
        ElapsedStep.yearsMonths,
      );
      expect(
        elapsedBetween(DateTime(2016, 9, 29, 10, 1), now).step,
        ElapsedStep.yearsMonths,
      );
      expect(elapsedBetween(DateTime(2016, 9, 29, 10), now), (
        step: ElapsedStep.years,
        first: 10,
        second: 0,
      ));
    });
  });

  test('years and months follow the calendar', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final at = DateTime(2025, 10, 6, 10);
    expect(
      en.elapsed(elapsedBetween(at, DateTime(2026, 10, 6, 10))),
      '1 year ago',
    );
    expect(
      en.elapsed(elapsedBetween(at, DateTime(2026, 10, 6, 9, 59))),
      '11 mo 29 d ago',
    );
    expect(
      en.elapsed(
        elapsedBetween(DateTime(2026, 1, 31, 12), DateTime(2026, 2, 28, 12)),
      ),
      '1 month ago',
    );
  });

  test('months count from the wall time where the intake happened', () {
    // Logged at 23:00 in UTC+3, read in UTC: still a full month on the
    // intake's own calendar.
    final at = DateTime.utc(2026, 8, 29, 20);
    final wallAt = DateTime.utc(2026, 8, 29, 23);
    expect(
      elapsedBetween(at, DateTime(2026, 9, 29, 23), wallAt: wallAt).step,
      ElapsedStep.monthsDays,
    );
  });

  test('day and time', () async {
    final ru = await AppLocalizations.delegate.load(const Locale('ru'));
    expect(ru.dayAndTime(DateTime(2026, 9, 29, 8, 5), now), 'Сегодня, 08:05');
    expect(ru.dayAndTime(DateTime(2026, 9, 28, 23), now), 'Вчера, 23:00');
    expect(ru.dose(0.25, 'г'), '0,25 г');
  });

  test('doses without a unit', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.dose(2, ''), '2');
  });

  test('parseAmount accepts a comma and rejects non-positive values', () {
    expect(parseAmount('12,5'), 12.5);
    expect(parseAmount(' 3 '), 3);
    expect(parseAmount('0'), isNull);
    expect(parseAmount('abc'), isNull);
  });
}
