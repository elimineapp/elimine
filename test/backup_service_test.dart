import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/core/db/queries.dart';
import 'package:elimine/features/backup/backup_format.dart';
import 'package:elimine/features/backup/backup_service.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Export from one database, import into another.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime(2026, 10, 4, 14);
  late AppDatabase source;
  late AppDatabase target;

  setUp(() {
    source = AppDatabase(NativeDatabase.memory());
    target = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await source.close();
    await target.close();
  });

  BackupService backup(AppDatabase db) => BackupService(db, clock: () => now);
  List<BackupSubstance> decode(String json) => decodeBackup(json, now: now);

  /// Two substances, one archived, with doses, intakes with and without a
  /// dose, and one intake deleted with a swipe.
  Future<void> fill(AppDatabase db) async {
    final substances = SubstanceService(db, clock: () => now);
    final intakes = IntakeService(db, clock: () => now);
    final coffee = await substances.create((
      name: 'Coffee',
      unit: 'mg',
      color: 'orange',
      icon: 'coffee',
      doses: [200, 100],
    ));
    final old = await substances.create((
      name: 'Old',
      unit: '',
      color: 'violet',
      icon: 'leaf',
      doses: const [],
    ));
    await intakes.log(
      substanceId: coffee,
      amount: 100,
      takenAt: DateTime(2026, 9, 28, 23, 30),
    );
    await intakes.log(substanceId: coffee, amount: null);
    await intakes.delete(await intakes.log(substanceId: coffee, amount: 200));
    await intakes.log(
      substanceId: old,
      amount: 1.5,
      takenAt: DateTime(2025, 1, 2, 3, 4),
    );
    await substances.archive(old);
  }

  test('restoring into an empty database reproduces the data', () async {
    await fill(source);
    final json = await backup(source).export();

    final plan = await backup(target).plan(decode(json));
    expect((plan.newSubstances, plan.newIntakes), (2, 3));
    expect((plan.presentSubstances, plan.presentIntakes), (0, 0));
    await backup(target).apply(plan);

    // Same data in the same order, archive state and offsets included.
    expect(await backup(target).export(), json);
    expect(await target.select(target.intakes).get(), hasLength(3));
  });

  test('a backup keeps the order set by moving', () async {
    final substances = SubstanceService(source, clock: () => now);
    Future<String> create(String name) => substances.create((
      name: name,
      unit: '',
      color: 'green',
      icon: 'pill',
      doses: const [],
    ));
    final coffee = await create('Coffee');
    await create('Melatonin');
    final ibuprofen = await create('Ibuprofen');
    await substances.move(ibuprofen, beforeId: coffee);

    final json = await backup(source).export();
    await backup(target).apply(await backup(target).plan(decode(json)));

    expect(
      [
        for (final i in await target.watchSubstancesWithLast().first)
          i.substance.name,
      ],
      ['Ibuprofen', 'Coffee', 'Melatonin'],
    );
  });

  test('device settings stay out of backups', () async {
    await fill(source);
    await SettingsService(source).setWeekStart(DateTime.sunday);
    await SettingsService(source).setSheetExpanded();
    final json = await backup(source).export();
    await backup(target).apply(await backup(target).plan(decode(json)));

    expect(json, isNot(contains('sheetExpanded')));
    expect(json, isNot(contains('weekStart')));
    expect(await target.select(target.settings).get(), isEmpty);
  });

  test('importing the same file again adds nothing', () async {
    await fill(source);
    final json = await backup(source).export();
    await backup(target).apply(await backup(target).plan(decode(json)));

    final again = await backup(target).plan(decode(json));
    expect(again.addsNothing, isTrue);
    expect((again.presentSubstances, again.presentIntakes), (2, 3));
    await backup(target).apply(again);
    expect(await target.select(target.intakes).get(), hasLength(3));
    expect(await target.select(target.substances).get(), hasLength(2));
  });

  test(
    'older intakes join an existing substance, which stays as it is',
    () async {
      final id = await SubstanceService(target).create((
        name: 'Coffee',
        unit: 'mg',
        color: 'blue',
        icon: 'coffee',
        doses: const [50],
      ));
      await IntakeService(
        target,
        clock: () => now,
      ).log(substanceId: id, amount: 50);

      final file = encodeBackup([
        BackupSubstance(
          id: id,
          name: 'Renamed in the file',
          unit: 'g',
          doses: const [1],
          intakes: [
            BackupIntake(
              id: '01999b5e-7c2a-7d3e-9f10-2b4c6d8e0a12',
              takenAt: DateTime.utc(2024, 5, 1, 10),
              tzOffsetMin: 180,
            ),
          ],
        ),
      ], now: now);
      final plan = await backup(target).plan(decode(file));
      expect(
        (plan.newSubstances, plan.newIntakes, plan.presentSubstances),
        (0, 1, 1),
      );
      await backup(target).apply(plan);

      final substance = (await target.watchSubstance(id).first)!;
      expect((substance.name, substance.unit), ('Coffee', 'mg'));
      expect((await target.dosesFor(id)).map((d) => d.amount), [50]);
      final intakes = await target.watchIntakesFor(id).first;
      expect(intakes, hasLength(2));
      expect(intakes.last.tzOffsetMin, 180);
    },
  );

  test('new substances go last and get a free color by default', () async {
    await SubstanceService(target).create((
      name: 'Existing',
      unit: '',
      color: 'blue',
      icon: 'pill',
      doses: const [],
    ));
    final file = encodeBackup(const [
      BackupSubstance(id: '01999b5e-7c2a-7d3e-9f10-2b4c6d8e0a20', name: 'A'),
      BackupSubstance(id: '01999b5e-7c2a-7d3e-9f10-2b4c6d8e0a21', name: 'B'),
    ], now: now);
    await backup(target).apply(await backup(target).plan(decode(file)));

    final items = await target.watchSubstancesWithLast().first;
    expect(
      [for (final i in items) (i.substance.name, i.substance.color)],
      [('Existing', 'blue'), ('A', 'orange'), ('B', 'aqua')],
    );
    expect(items.last.substance.icon, 'pill');
  });
}
