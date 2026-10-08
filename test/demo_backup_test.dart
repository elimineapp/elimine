import 'package:drift/native.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/features/backup/backup_format.dart';
import 'package:elimine/features/backup/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/demo_backup.dart';

void main() {
  final now = DateTime(2026, 10, 4, 14);
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  BackupService backup() => BackupService(db, clock: () => now);

  test('the demo backup imports into an empty database', () async {
    final substances = decodeBackup(demoBackupJson(now), now: now);
    expect(
      [for (final s in substances) s.name],
      ['Coffee', 'Melatonin', 'Ibuprofen', 'Alcohol', 'Nicotine'],
    );
    final intakes = substances.expand((s) => s.intakes).length;

    final plan = await backup().plan(substances);
    expect((plan.newSubstances, plan.newIntakes), (5, intakes));
    await backup().apply(plan);

    expect(await db.select(db.substances).get(), hasLength(5));
    expect(await db.select(db.intakes).get(), hasLength(intakes));
  });

  test('the demo backup is the same on every run', () {
    expect(demoBackupJson(now), demoBackupJson(now));
  });

  test('importing the demo backup again adds nothing', () async {
    final substances = decodeBackup(demoBackupJson(now), now: now);
    await backup().apply(await backup().plan(substances));

    final again = await backup().plan(substances);
    expect(again.addsNothing, isTrue);
  });

  test('the last coffee was two hours ago and nicotine was given up', () {
    final substances = decodeBackup(demoBackupJson(now), now: now);
    DateTime last(String name) => substances
        .firstWhere((s) => s.name == name)
        .intakes
        .map((i) => i.takenAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    expect(now.difference(last('Coffee').toLocal()), const Duration(hours: 2));
    expect(now.difference(last('Nicotine')).inDays, greaterThan(90));
  });
}
