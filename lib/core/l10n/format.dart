import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../db/database.dart';

/// Wall-clock time of the intake in the zone it was logged in, as a UTC
/// [DateTime] whose fields read as that local time.
DateTime intakeWallTime(Intake intake) =>
    intake.takenAt.toUtc().add(Duration(minutes: intake.tzOffsetMin));

/// Whole calendar days from [day] to [now], compared by date only.
int calendarDaysBetween(DateTime day, DateTime now) => DateTime.utc(
  now.year,
  now.month,
  now.day,
).difference(DateTime.utc(day.year, day.month, day.day)).inDays;

extension ElimineFormat on AppLocalizations {
  String amount(double value) =>
      NumberFormat.decimalPattern(localeName).format(value);

  /// "250 mg", or just "2" for a substance without a unit.
  String dose(double value, String unit) =>
      unit.isEmpty ? amount(value) : '${amount(value)} $unit';

  /// "today", "yesterday", "12 days ago", "2 months ago", "1 year ago".
  String relativeDay(DateTime day, DateTime now) {
    final days = calendarDaysBetween(day, now);
    return switch (days) {
      <= 0 => relativeToday,
      1 => relativeYesterday,
      < 30 => relativeDaysAgo(days),
      < 365 => relativeMonthsAgo(days ~/ 30),
      _ => relativeYearsAgo(days ~/ 365),
    };
  }

  /// "Today, 14:35", "Yesterday, 09:10", "12 Sep, 18:00", "3 Jan 2025, 18:00".
  String dayAndTime(DateTime at, DateTime now) {
    final time = DateFormat.Hm(localeName).format(at);
    final day = switch (calendarDaysBetween(at, now)) {
      0 => dayToday,
      1 => dayYesterday,
      _ when at.year == now.year => DateFormat.MMMd(localeName).format(at),
      _ => DateFormat.yMMMd(localeName).format(at),
    };
    return '$day, $time';
  }

  String intakeTime(Intake intake, DateTime now) =>
      dayAndTime(intakeWallTime(intake), now);

  List<String> get unitSuggestionList => unitSuggestions.split(',');
}

/// Parses a positive amount typed with either a dot or a comma.
double? parseAmount(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value != null && value > 0 && value.isFinite ? value : null;
}
