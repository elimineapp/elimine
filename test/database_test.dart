import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/core/db/queries.dart';
import 'package:elimine/core/l10n/format.dart';
import 'package:elimine/features/analytics/analytics_queries.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SubstanceService substances;
  late IntakeService intakes;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    substances = SubstanceService(db);
    intakes = IntakeService(db);
  });
  tearDown(() => db.close());

  Future<String> create(String name, {List<double> doses = const []}) =>
      substances.create((
        name: '  $name ',
        unit: 'mg',
        color: 'green',
        icon: 'pill',
        doses: doses,
      ));

  test('the database starts empty: no built-in substances', () async {
    expect(await db.select(db.substances).get(), isEmpty);
  });

  group('SubstanceService', () {
    test(
      'creates in order with trimmed name and sorted unique doses',
      () async {
        final a = await create('A', doses: [25, 10, 25]);
        await create('B');

        final items = await db.watchSubstancesWithLast().first;
        expect(items.map((i) => i.substance.name), ['A', 'B']);
        expect((await db.dosesFor(a)).map((d) => d.amount), [10, 25]);
      },
    );

    test('update replaces doses and archive hides the substance', () async {
      final id = await create('A', doses: [10, 25]);
      await substances.update(id, (
        name: 'A2',
        unit: 'g',
        color: 'red',
        icon: 'drop',
        doses: [0.5],
      ));

      final s = (await db.watchSubstance(id).first)!;
      expect((s.name, s.unit, s.color, s.icon), ('A2', 'g', 'red', 'drop'));
      expect((await db.dosesFor(id)).map((d) => d.amount), [0.5]);

      await intakes.log(substanceId: id, amount: 1);
      await substances.archive(id);
      expect(await db.watchSubstancesWithLast().first, isEmpty);
      expect(await db.watchIntakesFor(id).first, hasLength(1));
    });
  });

  group('deleting and restoring', () {
    test('delete removes the substance, its doses and all intakes', () async {
      final gone = await create('Gone', doses: [1, 2]);
      final kept = await create('Kept', doses: [5]);
      final removed = await intakes.log(substanceId: gone, amount: 1);
      await intakes.delete(removed);
      await intakes.log(substanceId: gone, amount: null);
      await intakes.log(substanceId: kept, amount: 5);

      await substances.delete(gone);

      expect((await db.select(db.substances).get()).map((s) => s.id), [kept]);
      expect((await db.select(db.doses).get()).map((d) => d.substanceId), [
        kept,
      ]);
      expect((await db.select(db.intakes).get()).map((i) => i.substanceId), [
        kept,
      ]);
    });

    test('counts ignore soft-deleted intakes', () async {
      final a = await create('A');
      final b = await create('B');
      await intakes.log(substanceId: a, amount: 1);
      await intakes.delete(await intakes.log(substanceId: a, amount: 2));
      await substances.archive(a);
      await substances.archive(b);

      expect(await db.countIntakes(a), 1);
      final archived = await db.watchArchivedSubstances().first;
      expect(
        [
          for (final (:substance, :intakes) in archived)
            (substance.name, intakes),
        ],
        [('A', 1), ('B', 0)],
      );
    });

    test('restore brings an archived substance back in its place', () async {
      await create('A');
      final b = await create('B');
      await create('C');
      await substances.archive(b);
      expect(
        (await db.watchSubstancesWithLast().first).map((i) => i.substance.id),
        isNot(contains(b)),
      );

      await substances.restore(b);
      expect(
        (await db.watchSubstancesWithLast().first)
            .map((i) => i.substance.name)
            .take(2),
        ['A', 'B'],
      );
    });
  });

  group('IntakeService', () {
    test('clamps a future time to now', () async {
      final now = DateTime(2026, 9, 29, 12);
      final service = IntakeService(db, clock: () => now);
      final id = await create('A');
      await service.log(
        substanceId: id,
        amount: 1,
        takenAt: now.add(const Duration(hours: 3)),
      );
      expect((await db.watchIntakesFor(id).first).single.takenAt, now);
    });

    test('logs an intake without a dose', () async {
      final id = await create('A');
      await intakes.log(substanceId: id, amount: null);
      final logged = (await db.watchIntakesFor(id).first).single;
      expect(logged.amount, isNull);
      expect(
        (await db.watchSubstancesWithLast().first).single.last?.id,
        logged.id,
      );
    });

    test(
      'soft delete hides an intake everywhere; restore brings it back',
      () async {
        final id = await create('A');
        final older = await intakes.log(
          substanceId: id,
          amount: 10,
          takenAt: DateTime(2026, 9, 1),
        );
        final newer = await intakes.log(
          substanceId: id,
          amount: 25,
          takenAt: DateTime(2026, 9, 2),
        );

        await intakes.delete(newer);
        expect(
          (await db.watchSubstancesWithLast().first).single.last?.id,
          older,
        );
        expect(await db.watchRecentIntakes().first, hasLength(1));
        expect(await db.hasIntakes(id), isTrue);

        await intakes.delete(older);
        expect((await db.watchSubstancesWithLast().first).single.last, isNull);
        expect(await db.hasIntakes(id), isFalse);

        await intakes.restore(newer);
        expect(
          (await db.watchSubstancesWithLast().first).single.last?.id,
          newer,
        );
      },
    );
  });

  group('editing an intake', () {
    final now = DateTime(2026, 9, 29, 12);
    late IntakeService service;
    late String substanceId;

    setUp(() async {
      service = IntakeService(db, clock: () => now);
      substanceId = await create('A');
    });

    Future<Intake> single() async =>
        (await db.watchIntakesFor(substanceId).first).single;

    Future<Intake> logAt(DateTime at, double? amount) async {
      await service.log(substanceId: substanceId, amount: amount, takenAt: at);
      return single();
    }

    test('adds and clears a dose, keeping the time', () async {
      final before = await logAt(DateTime(2026, 9, 28, 9, 10), null);

      final wall = intakeWallTime(before);
      expect(await service.edit(before, wallTime: wall, amount: 250), isTrue);
      final dosed = await single();
      expect(dosed.amount, 250);
      expect(dosed.takenAt, before.takenAt);
      expect(dosed.tzOffsetMin, before.tzOffsetMin);

      expect(await service.edit(dosed, wallTime: wall, amount: null), isTrue);
      expect((await single()).amount, isNull);
    });

    test('reads a new time in the zone the intake was logged in', () async {
      // 23:30 in UTC+10, whatever the zone of the test machine.
      await db
          .into(db.intakes)
          .insert(
            IntakesCompanion.insert(
              substanceId: substanceId,
              amount: const Value(10),
              takenAt: DateTime.utc(2026, 9, 1, 13, 30),
              tzOffsetMin: 600,
            ),
          );
      final before = await single();

      await service.edit(
        before,
        wallTime: DateTime(2026, 8, 30, 22),
        amount: 10,
      );
      final after = await single();
      expect(after.tzOffsetMin, 600);
      expect(intakeWallTime(after), DateTime.utc(2026, 8, 30, 22));
    });

    test(
      '"Now" and a future time take the current moment and offset',
      () async {
        final before = await logAt(DateTime(2026, 9, 20, 8), 5);
        final offset = now.timeZoneOffset.inMinutes;

        await service.edit(before, wallTime: null, amount: 5);
        var after = await single();
        expect(after.takenAt, now);
        expect(after.tzOffsetMin, offset);

        await service.edit(
          after,
          wallTime: DateTime(2026, 9, 29, 15),
          amount: 5,
        );
        after = await single();
        expect(after.takenAt, now);
        expect(after.tzOffsetMin, offset);
      },
    );

    test('nothing changed: no write', () async {
      final before = await logAt(DateTime(2026, 9, 28, 9, 10), 5);
      final later = IntakeService(db, clock: () => DateTime(2026, 10, 1));

      expect(
        await later.edit(before, wallTime: intakeWallTime(before), amount: 5),
        isFalse,
      );
      expect((await single()).updatedAt, before.updatedAt);
    });

    test('revert restores the previous time and dose', () async {
      final before = await logAt(DateTime(2026, 9, 28, 9, 10), 5);

      await service.edit(
        before,
        wallTime: DateTime(2026, 9, 25, 20),
        amount: null,
      );
      await service.revert(before);
      final after = await single();
      expect(after.takenAt, before.takenAt);
      expect(after.tzOffsetMin, before.tzOffsetMin);
      expect(after.amount, 5);
    });
  });

  test('daily totals group by the local day at the moment of intake', () async {
    final id = await create('A');
    Future<void> insert(DateTime utc, int offsetMin) => db
        .into(db.intakes)
        .insert(
          IntakesCompanion.insert(
            substanceId: id,
            amount: const Value(10),
            takenAt: utc,
            tzOffsetMin: offsetMin,
          ),
        );

    // 22:30 UTC is already the next day in Moscow (+3), but still the same
    // day in New York (-4).
    await insert(DateTime.utc(2026, 9, 1, 22, 30), 180);
    await insert(DateTime.utc(2026, 9, 1, 22, 30), -240);
    await insert(DateTime.utc(2026, 9, 2, 10), 180);

    final totals = await db
        .watchDailyTotals(since: DateTime.utc(2026, 8, 1))
        .first;
    final other = await create('B');
    await intakes.log(substanceId: other, amount: 1);
    await intakes.log(substanceId: other, amount: null);
    final mixed = (await db.watchDailyTotals(substanceId: other).first).single;
    expect((mixed.total, mixed.count, mixed.dosed), (1.0, 2, 1));
    expect(
      {for (final t in totals) t.day: (t.total, t.count, t.dosed)},
      {'2026-09-01': (10.0, 1, 1), '2026-09-02': (20.0, 2, 2)},
    );
  });

  test(
    'daily totals stop before until; first intake day per substance',
    () async {
      final a = await create('A');
      final b = await create('B');
      expect(await db.watchFirstIntakeDay().first, isNull);

      await intakes.log(
        substanceId: a,
        amount: 1,
        takenAt: DateTime(2026, 9, 10, 12),
      );
      await intakes.log(
        substanceId: a,
        amount: 1,
        takenAt: DateTime(2026, 9, 20, 12),
      );
      final early = await intakes.log(
        substanceId: b,
        amount: 1,
        takenAt: DateTime(2026, 8, 1, 12),
      );
      await intakes.log(
        substanceId: b,
        amount: 1,
        takenAt: DateTime(2026, 9, 15, 12),
      );

      final bounded = await db
          .watchDailyTotals(
            since: DateTime(2026, 9, 1),
            until: DateTime(2026, 9, 16),
          )
          .first;
      expect(bounded.map((t) => t.day), ['2026-09-10', '2026-09-15']);

      expect(await db.watchFirstIntakeDay().first, DateTime.utc(2026, 8, 1));
      expect(
        await db.watchFirstIntakeDay(substanceId: a).first,
        DateTime.utc(2026, 9, 10),
      );
      // A deleted intake is not the first one any more.
      await intakes.delete(early);
      expect(await db.watchFirstIntakeDay().first, DateTime.utc(2026, 9, 10));
      expect(
        await db.watchFirstIntakeDay(substanceId: b).first,
        DateTime.utc(2026, 9, 15),
      );
    },
  );

  test('the week starts on Monday until Sunday is chosen', () async {
    final settings = SettingsService(db);
    expect(await settings.watchWeekStart().first, DateTime.monday);
    await settings.setWeekStart(DateTime.sunday);
    expect(await settings.watchWeekStart().first, DateTime.sunday);
    await settings.setWeekStart(DateTime.monday);
    expect(await settings.watchWeekStart().first, DateTime.monday);
    expect(await db.select(db.settings).get(), hasLength(1));
  });

  test('a substance screen counts as expanded once it has been', () async {
    final settings = SettingsService(db);
    expect(await settings.watchSheetExpanded().first, isFalse);
    await settings.setSheetExpanded();
    expect(await settings.watchSheetExpanded().first, isTrue);
    await settings.setSheetExpanded();
    expect(await db.select(db.settings).get(), hasLength(1));
  });
}
