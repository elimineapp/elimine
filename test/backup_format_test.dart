import 'dart:convert';
import 'dart:io';

import 'package:elimine/features/backup/backup_format.dart';
import 'package:flutter_test/flutter_test.dart';

const _s1 = '01a1044e-8cdc-79fb-bc15-17f680997024';
const _i1 = '01a1044e-8cdc-79fb-bc15-17f680997025';
const _i2 = '01a1044e-8cdc-79fb-bc15-17f680997026';

void main() {
  final now = DateTime.utc(2026, 10, 4, 4);

  String file(List<Object?> substances, {int version = 1}) => jsonEncode({
    'format': 'elimine-backup',
    'version': version,
    'exportedAt': '2026-10-04T14:00:00+10:00',
    'substances': substances,
  });

  Matcher rejectedAt(String path) =>
      throwsA(isA<BackupFormatException>().having((e) => e.path, 'path', path));

  test('round trip keeps ids, values, times and offsets', () {
    final original = [
      BackupSubstance(
        id: _s1,
        name: 'Coffee',
        unit: 'mg',
        color: 'orange',
        icon: 'coffee',
        archived: true,
        doses: const [100, 0.5],
        intakes: [
          BackupIntake(
            id: _i1,
            takenAt: DateTime.utc(2026, 9, 28, 13, 30),
            tzOffsetMin: 600,
            amount: 100,
          ),
          BackupIntake(
            id: _i2,
            takenAt: DateTime.utc(2026, 9, 1, 22, 15, 7),
            tzOffsetMin: -270,
          ),
        ],
      ),
    ];
    final json = encodeBackup(original, now: now);
    expect(json, contains('"takenAt": "2026-09-28T23:30:00+10:00"'));
    expect(json, contains('"takenAt": "2026-09-01T17:45:07-04:30"'));
    expect(json, contains('"doses": [\n        100,\n        0.5\n      ]'));

    final [s] = decodeBackup(json, now: now);
    expect(
      (s.id, s.name, s.unit, s.color, s.icon, s.archived),
      (_s1, 'Coffee', 'mg', 'orange', 'coffee', true),
    );
    expect(s.doses, [100.0, 0.5]);
    final [a, b] = s.intakes;
    expect(
      (a.id, a.takenAt, a.tzOffsetMin, a.amount),
      (_i1, DateTime.utc(2026, 9, 28, 13, 30), 600, 100.0),
    );
    expect(
      (b.takenAt, b.tzOffsetMin, b.amount),
      (DateTime.utc(2026, 9, 1, 22, 15, 7), -270, null),
    );
  });

  test('a minimal file gets defaults; unknown color and icon fall back', () {
    final [s] = decodeBackup(
      file([
        {
          'id': _s1,
          'name': ' Tea ',
          'color': 'ultraviolet',
          'icon': 'teapot',
          'intakes': [
            {'id': _i1, 'takenAt': '2026-10-01T08:00Z'},
          ],
        },
      ]),
      now: now,
    );
    expect(
      (s.name, s.unit, s.color, s.icon, s.archived),
      ('Tea', '', null, null, false),
    );
    expect(s.doses, isEmpty);
    expect(s.intakes.single.amount, isNull);
    expect(s.intakes.single.tzOffsetMin, 0);
  });

  group('rejects', () {
    Map<String, Object?> substance([Map<String, Object?> changes = const {}]) =>
        {
          'id': _s1,
          'name': 'X',
          'intakes': [
            {'id': _i1, 'takenAt': '2026-10-01T08:00:00+03:00', 'amount': 1},
          ],
          ...changes,
        };
    Map<String, Object?> withIntake(Map<String, Object?> intake) => substance({
      'intakes': [
        {'id': _i1, 'takenAt': '2026-10-01T08:00:00+03:00', ...intake},
      ],
    });

    test('files that are not backups', () {
      expect(() => decodeBackup('nope', now: now), rejectedAt(''));
      expect(
        () => decodeBackup('{"format":"other","version":1}', now: now),
        rejectedAt('format'),
      );
      expect(
        () => decodeBackup(file([], version: 0), now: now),
        rejectedAt('version'),
      );
    });

    test('a newer version', () {
      expect(
        () => decodeBackup(file([], version: 2), now: now),
        throwsA(isA<BackupVersionException>()),
      );
    });

    test('bad substances', () {
      expect(
        () => decodeBackup(
          file([
            substance({'id': 'x'}),
          ]),
          now: now,
        ),
        rejectedAt('substances[0].id'),
      );
      expect(
        () => decodeBackup(
          file([
            substance({'name': '  '}),
          ]),
          now: now,
        ),
        rejectedAt('substances[0].name'),
      );
      expect(
        () => decodeBackup(
          file([
            substance({
              'doses': [1, 0],
            }),
          ]),
          now: now,
        ),
        rejectedAt('substances[0].doses[1]'),
      );
      expect(
        () => decodeBackup(
          file([
            substance(),
            substance({'intakes': []}),
          ]),
          now: now,
        ),
        rejectedAt('substances[1].id'),
      );
    });

    test('bad intakes', () {
      expect(
        () => decodeBackup(
          file([
            withIntake({'takenAt': null}),
          ]),
          now: now,
        ),
        rejectedAt('substances[0].intakes[0].takenAt'),
      );
      // No offset: the local day would be ambiguous.
      expect(
        () => decodeBackup(
          file([
            withIntake({'takenAt': '2026-10-01T08:00:00'}),
          ]),
          now: now,
        ),
        rejectedAt('substances[0].intakes[0].takenAt'),
      );
      expect(
        () => decodeBackup(
          file([
            withIntake({'takenAt': '2026-02-30T08:00:00Z'}),
          ]),
          now: now,
        ),
        rejectedAt('substances[0].intakes[0].takenAt'),
      );
      expect(
        () => decodeBackup(
          file([
            withIntake({'takenAt': '2026-10-05T08:00:00Z'}),
          ]),
          now: now,
        ),
        rejectedAt('substances[0].intakes[0].takenAt'),
      );
      expect(
        () => decodeBackup(
          file([
            withIntake({'amount': -1}),
          ]),
          now: now,
        ),
        rejectedAt('substances[0].intakes[0].amount'),
      );
      expect(
        () => decodeBackup(
          file([
            withIntake({'id': 42}),
          ]),
          now: now,
        ),
        rejectedAt('substances[0].intakes[0].id'),
      );
    });
  });

  test('the example in docs/backup-format.md decodes', () {
    final doc = File('docs/backup-format.md').readAsStringSync();
    final example = RegExp(
      r'## Example\s+```json\n(.*?)\n```',
      dotAll: true,
    ).firstMatch(doc)![1]!;

    final substances = decodeBackup(example, now: now);
    expect(substances.map((s) => s.name), ['Coffee', 'Melatonin']);
    expect(substances.first.intakes, hasLength(2));
    expect(substances.last.unit, '');
  });
}
