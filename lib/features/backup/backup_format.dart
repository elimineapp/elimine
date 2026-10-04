import 'dart:convert';

import '../../core/appearance.dart';

/// The public backup file format, documented in `docs/backup-format.md`.
/// Converters from other trackers write it too, so decoding is strict about
/// what it needs and lenient about what it can default.
const backupFormatName = 'elimine-backup';

/// The newest version this app writes and reads; older ones stay readable.
const backupFormatVersion = 1;

class BackupIntake {
  const BackupIntake({
    required this.id,
    required this.takenAt,
    required this.tzOffsetMin,
    this.amount,
  });

  final String id;

  /// UTC instant.
  final DateTime takenAt;

  /// The UTC offset at that moment, which fixes the local calendar day.
  final int tzOffsetMin;
  final double? amount;
}

class BackupSubstance {
  const BackupSubstance({
    required this.id,
    required this.name,
    this.unit = '',
    this.color,
    this.icon,
    this.archived = false,
    this.doses = const [],
    this.intakes = const [],
  });

  final String id;
  final String name;
  final String unit;

  /// A palette key, or null when missing or unknown: the importer picks one.
  final String? color;

  /// An icon key, or null when missing or unknown.
  final String? icon;
  final bool archived;
  final List<double> doses;
  final List<BackupIntake> intakes;
}

/// A file that is not a valid backup. [path] points at the offending value,
/// e.g. `substances[0].intakes[11].takenAt`.
class BackupFormatException implements Exception {
  const BackupFormatException(this.path, this.problem);

  final String path;
  final String problem;

  @override
  String toString() => path.isEmpty ? problem : '$path: $problem';
}

/// A backup written by a newer app than this one.
class BackupVersionException implements Exception {
  const BackupVersionException(this.version);

  final int version;

  @override
  String toString() => 'Backup format version $version is not supported';
}

String encodeBackup(List<BackupSubstance> substances, {required DateTime now}) {
  return const JsonEncoder.withIndent('  ').convert({
    'format': backupFormatName,
    'version': backupFormatVersion,
    'exportedAt': formatBackupTime(now.toUtc(), now.timeZoneOffset.inMinutes),
    'substances': [
      for (final s in substances)
        {
          'id': s.id,
          'name': s.name,
          'unit': s.unit,
          'color': ?s.color,
          'icon': ?s.icon,
          'archived': s.archived,
          'doses': [for (final d in s.doses) _number(d)],
          'intakes': [
            for (final i in s.intakes)
              {
                'id': i.id,
                'takenAt': formatBackupTime(i.takenAt, i.tzOffsetMin),
                'amount': i.amount == null ? null : _number(i.amount!),
              },
          ],
        },
    ],
  });
}

/// Parses and validates a backup. Throws [BackupFormatException] at the first
/// problem, or [BackupVersionException] for a newer format. Times later than
/// [now] are rejected, as the app never records future intakes.
List<BackupSubstance> decodeBackup(String source, {required DateTime now}) {
  final Object? root;
  try {
    root = jsonDecode(source);
  } on FormatException {
    throw const BackupFormatException('', 'not valid JSON');
  }
  final r = _Reader(now.toUtc());
  final doc = r.map(root, '');
  if (doc['format'] != backupFormatName) {
    throw const BackupFormatException('format', 'not an Elimine backup');
  }
  final version = doc['version'];
  if (version is! int || version < 1) {
    throw const BackupFormatException('version', 'must be a positive integer');
  }
  if (version > backupFormatVersion) throw BackupVersionException(version);

  final list = r.list(doc['substances'], 'substances', required: true);
  return [for (final (i, s) in list.indexed) r.substance(s, 'substances[$i]')];
}

/// `2026-10-04T13:25:00+10:00`: the local wall-clock time and its offset.
String formatBackupTime(DateTime utc, int offsetMin) {
  final local = utc.toUtc().add(Duration(minutes: offsetMin));
  String two(int v) => v.toString().padLeft(2, '0');
  final sign = offsetMin < 0 ? '-' : '+';
  final abs = offsetMin.abs();
  return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-'
      '${two(local.day)}T${two(local.hour)}:${two(local.minute)}:'
      '${two(local.second)}$sign${two(abs ~/ 60)}:${two(abs % 60)}';
}

/// The inverse of [formatBackupTime]; `Z` is offset zero. Seconds and a
/// fraction are optional. Null when [text] is not such a time; unlike
/// [DateTime.parse], the offset is kept.
({DateTime utc, int offsetMin})? parseBackupTime(String text) {
  final m = _timePattern.firstMatch(text);
  if (m == null) return null;
  final [y, mo, d, h, mi] = [for (var g = 1; g <= 5; g++) int.parse(m[g]!)];
  final s = int.parse(m[6] ?? '0');
  final zone = m[7]!;
  final offset = zone == 'Z'
      ? 0
      : (zone[0] == '-' ? -1 : 1) *
            (int.parse(zone.substring(1, 3)) * 60 +
                int.parse(zone.substring(4, 6)));
  final wall = DateTime.utc(y, mo, d, h, mi, s);
  // DateTime.utc rolls 31 February over to March; reject instead.
  if (wall.month != mo || wall.day != d || h > 23 || mi > 59 || s > 59) {
    return null;
  }
  if (offset.abs() > 18 * 60) return null;
  return (utc: wall.subtract(Duration(minutes: offset)), offsetMin: offset);
}

final _timePattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?'
  r'(Z|[+-]\d{2}:\d{2})$',
);

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{12}$',
);

/// Whole doses read better as `250` than `250.0`.
num _number(double v) => v == v.roundToDouble() ? v.toInt() : v;

class _Reader {
  _Reader(this.now);

  final DateTime now;
  final _substanceIds = <String>{};
  final _intakeIds = <String>{};

  Map<String, Object?> map(Object? value, String path) {
    if (value is Map<String, Object?>) return value;
    throw BackupFormatException(path, 'must be an object');
  }

  List<Object?> list(Object? value, String path, {bool required = false}) {
    if (value == null && !required) return const [];
    if (value is List<Object?>) return value;
    throw BackupFormatException(path, 'must be a list');
  }

  String id(Object? value, String path, Set<String> seen) {
    if (value is! String || !_uuidPattern.hasMatch(value)) {
      throw BackupFormatException(path, 'must be a UUID');
    }
    final id = value.toLowerCase();
    if (!seen.add(id)) throw BackupFormatException(path, 'is used twice');
    return id;
  }

  double positive(Object? value, String path) {
    if (value is num && value.isFinite && value > 0) return value.toDouble();
    throw BackupFormatException(path, 'must be a positive number');
  }

  BackupSubstance substance(Object? value, String path) {
    final s = map(value, path);
    final name = s['name'];
    if (name is! String || name.trim().isEmpty) {
      throw BackupFormatException('$path.name', 'must be a non-empty string');
    }
    final unit = s['unit'] ?? '';
    if (unit is! String) {
      throw BackupFormatException('$path.unit', 'must be a string');
    }
    final archived = s['archived'] ?? false;
    if (archived is! bool) {
      throw BackupFormatException('$path.archived', 'must be true or false');
    }
    final color = s['color'];
    final icon = s['icon'];
    return BackupSubstance(
      id: id(s['id'], '$path.id', _substanceIds),
      name: name.trim(),
      unit: unit.trim(),
      color: substanceColors.containsKey(color) ? color as String : null,
      icon: substanceIcons.containsKey(icon) ? icon as String : null,
      archived: archived,
      doses: [
        for (final (i, d) in list(s['doses'], '$path.doses').indexed)
          positive(d, '$path.doses[$i]'),
      ],
      intakes: [
        for (final (i, x) in list(s['intakes'], '$path.intakes').indexed)
          intake(x, '$path.intakes[$i]'),
      ],
    );
  }

  BackupIntake intake(Object? value, String path) {
    final x = map(value, path);
    final taken = x['takenAt'];
    final time = taken is String ? parseBackupTime(taken) : null;
    if (time == null) {
      throw BackupFormatException(
        '$path.takenAt',
        'must be a time like 2026-10-04T13:25:00+10:00',
      );
    }
    if (time.utc.isAfter(now)) {
      throw BackupFormatException('$path.takenAt', 'is in the future');
    }
    final amount = x['amount'];
    return BackupIntake(
      id: id(x['id'], '$path.id', _intakeIds),
      takenAt: time.utc,
      tzOffsetMin: time.offsetMin,
      amount: amount == null ? null : positive(amount, '$path.amount'),
    );
  }
}
