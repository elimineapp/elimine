import 'dart:math' as math;

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

/// How the time since an intake is told, from the shortest step to the
/// longest. Each step shows up to two units.
enum ElapsedStep {
  justNow,
  minutes,
  hours,
  daysHours,
  days,
  monthsDays,
  yearsMonths,
  years,
}

/// The time since a moment in its step: [first] is the larger unit and
/// [second] the smaller one, 0 when the step has a single unit.
typedef Elapsed = ({ElapsedStep step, int first, int second});

/// Splits the time from [at] to [now]. Minutes, hours and the first week are
/// real time passed; from then on months and years follow the calendar from
/// [wallAt], the wall-clock time of [at] where it happened (defaults to
/// [at]'s own fields), and days are whole days after the last full month.
Elapsed elapsedBetween(DateTime at, DateTime now, {DateTime? wallAt}) {
  final passed = now.difference(at);
  if (passed < const Duration(minutes: 1)) {
    return (step: ElapsedStep.justNow, first: 0, second: 0);
  }
  if (passed < const Duration(hours: 1)) {
    return (step: ElapsedStep.minutes, first: passed.inMinutes, second: 0);
  }
  if (passed < const Duration(days: 1)) {
    return (
      step: ElapsedStep.hours,
      first: passed.inHours,
      second: passed.inMinutes % 60,
    );
  }
  if (passed < const Duration(days: 7)) {
    return (
      step: ElapsedStep.daysHours,
      first: passed.inDays,
      second: passed.inHours % 24,
    );
  }

  final from = _fields(wallAt ?? at);
  final to = _fields(now);
  var months = (to.year - from.year) * 12 + to.month - from.month;
  if (_addMonths(from, months).isAfter(to)) months--;
  final days = to.difference(_addMonths(from, months)).inDays;
  return switch (months) {
    < 1 => (step: ElapsedStep.days, first: days, second: 0),
    < 12 => (step: ElapsedStep.monthsDays, first: months, second: days),
    < 120 => (
      step: ElapsedStep.yearsMonths,
      first: months ~/ 12,
      second: months % 12,
    ),
    _ => (step: ElapsedStep.years, first: months ~/ 12, second: 0),
  };
}

/// [time]'s fields as a UTC [DateTime], so calendar math skips DST shifts.
DateTime _fields(DateTime time) => DateTime.utc(
  time.year,
  time.month,
  time.day,
  time.hour,
  time.minute,
  time.second,
  time.millisecond,
  time.microsecond,
);

/// [time] plus [months] calendar months; a day the target month lacks
/// becomes its last day.
DateTime _addMonths(DateTime time, int months) {
  final index = time.month - 1 + months;
  final year = time.year + index ~/ 12;
  final month = index % 12 + 1;
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(
    year,
    month,
    math.min(time.day, lastDay),
    time.hour,
    time.minute,
    time.second,
    time.millisecond,
    time.microsecond,
  );
}

extension ElimineFormat on AppLocalizations {
  String amount(double value) =>
      NumberFormat.decimalPattern(localeName).format(value);

  /// "250 mg", or just "2" for a substance without a unit.
  String dose(double value, String unit) =>
      unit.isEmpty ? amount(value) : '${amount(value)} $unit';

  /// "just now", "5 h 12 min ago", "4 mo 12 d ago", "1 year 11 mo ago";
  /// a zero second unit is left out ("3 days ago").
  String elapsed(Elapsed value) {
    final (:step, :first, :second) = value;
    return switch (step) {
      ElapsedStep.justNow => elapsedJustNow,
      ElapsedStep.minutes => elapsedMinutes(first),
      ElapsedStep.hours when second == 0 => elapsedHours(first),
      ElapsedStep.hours => elapsedHoursMinutes(first, second),
      ElapsedStep.daysHours when second == 0 => elapsedDays(first),
      ElapsedStep.daysHours => elapsedDaysHours(first, second),
      ElapsedStep.days => elapsedDays(first),
      ElapsedStep.monthsDays when second == 0 => elapsedMonths(first),
      ElapsedStep.monthsDays => elapsedMonthsDays(first, second),
      ElapsedStep.yearsMonths when second == 0 => elapsedYears(first),
      ElapsedStep.yearsMonths => elapsedYearsMonths(first, second),
      ElapsedStep.years => elapsedYears(first),
    };
  }

  String elapsedSince(Intake intake, DateTime now) => elapsed(
    elapsedBetween(intake.takenAt, now, wallAt: intakeWallTime(intake)),
  );

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

  /// The last intake of a substance: "250 mg · 12 days ago", only the time
  /// since it when it had no dose, or "Not logged yet".
  String lastIntake(Intake? last, String unit, DateTime now) => switch (last) {
    null => neverLogged,
    Intake(:final amount) => [
      if (amount != null) dose(amount, unit),
      elapsedSince(last, now),
    ].join(' · '),
  };

  List<String> get unitSuggestionList => unitSuggestions.split(',');
}

/// Parses a positive amount typed with either a dot or a comma.
double? parseAmount(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value != null && value > 0 && value.isFinite ? value : null;
}
