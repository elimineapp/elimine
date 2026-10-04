import 'package:elimine/core/l10n/format.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru'));
  final now = DateTime(2026, 9, 29, 10);
  DateTime ago(int days) => now.subtract(Duration(days: days));

  test('relative day in English', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect([0, 1, 2, 21, 45, 400].map((d) => en.relativeDay(ago(d), now)), [
      'today',
      'yesterday',
      '2 days ago',
      '21 days ago',
      '1 month ago',
      '1 year ago',
    ]);
  });

  test('relative day in Russian uses plural forms', () async {
    final ru = await AppLocalizations.delegate.load(const Locale('ru'));
    expect([1, 2, 5, 21, 90, 800].map((d) => ru.relativeDay(ago(d), now)), [
      'вчера',
      '2 дня назад',
      '5 дней назад',
      '21 день назад',
      '3 мес. назад',
      '2 года назад',
    ]);
  });

  test('day and time', () async {
    final ru = await AppLocalizations.delegate.load(const Locale('ru'));
    expect(ru.dayAndTime(DateTime(2026, 9, 29, 8, 5), now), 'Сегодня, 08:05');
    expect(ru.dayAndTime(DateTime(2026, 9, 28, 23), now), 'Вчера, 23:00');
    expect(ru.dose(0.25, 'г'), '0,25 г');
  });

  test('doses without a unit or without a value', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ru = await AppLocalizations.delegate.load(const Locale('ru'));
    expect(en.dose(2, ''), '2');
    expect(en.optionalDose(250, 'mg'), '250 mg');
    expect(en.optionalDose(null, 'mg'), 'No dose');
    expect(ru.optionalDose(null, 'мг'), 'Без дозы');
  });

  test('parseAmount accepts a comma and rejects non-positive values', () {
    expect(parseAmount('12,5'), 12.5);
    expect(parseAmount(' 3 '), 3);
    expect(parseAmount('0'), isNull);
    expect(parseAmount('abc'), isNull);
  });
}
