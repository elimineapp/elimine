// Writes a backup file with demo data for screenshots:
//
//   dart run tool/demo_backup.dart demo.json [2026-10-08T09:41]
//
// The optional local time is the moment the history ends, now by default.
// It produces the public format (docs/backup-format.md) the way a converter
// from another tracker would, without the app's code. Ids are UUIDv5 of fixed
// names and the pattern comes from a fixed seed, so every run gives the same
// data, only dated relative to the moment it runs.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:uuid/uuid.dart';

void main(List<String> args) {
  if (args.isEmpty || args.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/demo_backup.dart <output.json> [local time]',
    );
    exit(64);
  }
  final now = args.length == 2 ? DateTime.parse(args[1]) : DateTime.now();
  File(args.first).writeAsStringSync(demoBackupJson(now));
}

/// About nine months of history ending at [now], in local time.
String demoBackupJson(DateTime now) {
  final random = Random(7);
  final today = DateTime(now.year, now.month, now.day);
  const days = 270;

  final substances = <_Substance>[
    _Substance('Coffee', 'cup', 'orange', 'coffee', [1, 2]),
    _Substance('Melatonin', 'mg', 'violet', 'moon', [1, 3]),
    _Substance('Ibuprofen', 'mg', 'blue', 'pill', [200, 400]),
    _Substance('Alcohol', 'ml', 'magenta', 'drink', [330, 500]),
    _Substance('Nicotine', '', 'green', 'smoke', []),
  ];
  final [coffee, melatonin, ibuprofen, alcohol, nicotine] = substances;

  DateTime at(int daysAgo, int hour, int minute) =>
      DateTime(today.year, today.month, today.day - daysAgo, hour, minute);

  var melatoninRun = 0;
  var ibuprofenIn = 6;
  for (var d = days; d >= 1; d--) {
    final day = at(d, 0, 0);

    // Coffee most mornings, sometimes again in the afternoon.
    if (random.nextDouble() < 0.9) {
      coffee.add(at(d, 8, random.nextInt(60)), random.nextBool() ? 1 : 2);
      if (random.nextDouble() < 0.35) {
        coffee.add(at(d, 15, random.nextInt(60)), 1);
      }
    }

    // Melatonin in runs of a few nights with longer gaps between them.
    if (melatoninRun == 0 && random.nextDouble() < 0.12) {
      melatoninRun = 3 + random.nextInt(5);
    }
    if (melatoninRun > 0) {
      melatonin.add(at(d, 23, random.nextInt(30)), random.nextBool() ? 1 : 3);
      melatoninRun--;
    }

    // Ibuprofen now and then; the dose is not always remembered.
    if (--ibuprofenIn == 0) {
      ibuprofen.add(
        at(d, 12 + random.nextInt(8), random.nextInt(60)),
        random.nextDouble() < 0.3 ? null : 400,
      );
      ibuprofenIn = 8 + random.nextInt(14);
    }

    // Alcohol on some Fridays and Saturdays.
    if ((day.weekday == DateTime.friday || day.weekday == DateTime.saturday) &&
        random.nextDouble() < 0.6) {
      alcohol.add(at(d, 20, random.nextInt(60)), random.nextBool() ? 330 : 500);
    }

    // Nicotine every day until it was given up about three months ago.
    if (d >= 95) {
      for (var i = 0; i < 1 + random.nextInt(2); i++) {
        nicotine.add(at(d, 10 + 6 * i, random.nextInt(60)), null);
      }
    }
  }
  // Today: this morning's coffee, two hours ago.
  coffee.add(now.subtract(const Duration(hours: 2)), 1);

  return const JsonEncoder.withIndent('  ').convert({
    'format': 'elimine-backup',
    'version': 1,
    'exportedAt': _time(now),
    'substances': [for (final s in substances) s.toJson()],
  });
}

class _Substance {
  _Substance(this.name, this.unit, this.color, this.icon, this.doses);

  final String name;
  final String unit;
  final String color;
  final String icon;
  final List<num> doses;
  final _intakes = <(DateTime, num?)>[];

  void add(DateTime takenAt, num? amount) => _intakes.add((takenAt, amount));

  Map<String, Object?> toJson() => {
    'id': _id(name),
    'name': name,
    'unit': unit,
    'color': color,
    'icon': icon,
    'doses': doses,
    'intakes': [
      for (final (i, (takenAt, amount)) in _intakes.indexed)
        {'id': _id('$name/$i'), 'takenAt': _time(takenAt), 'amount': amount},
    ],
  };
}

String _id(String name) =>
    const Uuid().v5(Namespace.url.value, 'https://elimine.app/demo/$name');

/// Local time with its UTC offset, e.g. `2026-10-04T08:15:00+10:00`.
String _time(DateTime local) {
  String two(int n) => n.toString().padLeft(2, '0');
  final offset = local.timeZoneOffset.inMinutes;
  final sign = offset < 0 ? '-' : '+';
  return '${local.year}-${two(local.month)}-${two(local.day)}'
      'T${two(local.hour)}:${two(local.minute)}:${two(local.second)}'
      '$sign${two(offset.abs() ~/ 60)}:${two(offset.abs() % 60)}';
}
