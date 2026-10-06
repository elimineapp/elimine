import 'package:drift/drift.dart';

import 'database.dart';

typedef SubstanceWithLast = ({Substance substance, Intake? last});
typedef IntakeWithSubstance = ({Intake intake, Substance substance});
typedef SubstanceWithCount = ({Substance substance, int intakes, Intake? last});

extension SharedQueries on AppDatabase {
  /// Id of the substance's latest non-deleted intake, for a join on the
  /// substances row.
  Expression<String> _latestIntakeId() => subqueryExpression<String>(
    selectOnly(intakes)
      ..addColumns([intakes.id])
      ..where(
        intakes.substanceId.equalsExp(substances.id) &
            intakes.deletedAt.isNull(),
      )
      ..orderBy([OrderingTerm.desc(intakes.takenAt)])
      ..limit(1),
  );

  /// Active substances with their latest intake, in the user's order.
  Stream<List<SubstanceWithLast>> watchSubstancesWithLast() {
    final latest = alias(intakes, 'latest');
    final latestId = _latestIntakeId();
    final query =
        select(substances)
            .join([leftOuterJoin(latest, latest.id.equalsExp(latestId))])
          ..where(substances.archivedAt.isNull())
          ..orderBy([
            OrderingTerm.asc(substances.sortOrder),
            OrderingTerm.asc(substances.id),
          ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (
            substance: row.readTable(substances),
            last: row.readTableOrNull(latest),
          ),
      ],
    );
  }

  Stream<Substance?> watchSubstance(String id) =>
      (select(substances)..where((s) => s.id.equals(id))).watchSingleOrNull();

  Future<List<Dose>> dosesFor(String substanceId) =>
      _dosesQuery(substanceId).get();

  Stream<List<Dose>> watchDoses(String substanceId) =>
      _dosesQuery(substanceId).watch();

  SimpleSelectStatement<$DosesTable, Dose> _dosesQuery(String substanceId) =>
      select(doses)
        ..where((d) => d.substanceId.equals(substanceId))
        ..orderBy([(d) => OrderingTerm.asc(d.sortOrder)]);

  /// Non-deleted intakes of one substance, newest first.
  Stream<List<Intake>> watchIntakesFor(String substanceId) =>
      (select(intakes)
            ..where(
              (i) => i.substanceId.equals(substanceId) & i.deletedAt.isNull(),
            )
            ..orderBy([(i) => OrderingTerm.desc(i.takenAt)]))
          .watch();

  Future<bool> hasIntakes(String substanceId) async {
    final row =
        await (selectOnly(intakes)
              ..addColumns([intakes.id])
              ..where(
                intakes.substanceId.equals(substanceId) &
                    intakes.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Visible (non-deleted) intakes of one substance.
  Future<int> countIntakes(String substanceId) async {
    final count = intakes.id.count();
    final row =
        await (selectOnly(intakes)
              ..addColumns([count])
              ..where(
                intakes.substanceId.equals(substanceId) &
                    intakes.deletedAt.isNull(),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Archived substances with their visible intake counts and latest
  /// intake, in the user's order.
  Stream<List<SubstanceWithCount>> watchArchivedSubstances() {
    final count = intakes.id.count();
    final latest = alias(intakes, 'latest');
    final query =
        select(substances).join([
            leftOuterJoin(
              intakes,
              intakes.substanceId.equalsExp(substances.id) &
                  intakes.deletedAt.isNull(),
              useColumns: false,
            ),
            leftOuterJoin(latest, latest.id.equalsExp(_latestIntakeId())),
          ])
          ..addColumns([count])
          ..where(substances.archivedAt.isNotNull())
          ..groupBy([substances.id])
          ..orderBy([
            OrderingTerm.asc(substances.sortOrder),
            OrderingTerm.asc(substances.id),
          ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (
            substance: row.readTable(substances),
            intakes: row.read(count) ?? 0,
            last: row.readTableOrNull(latest),
          ),
      ],
    );
  }

  /// The [limit] latest non-deleted intakes across all substances, newest
  /// first.
  Stream<List<IntakeWithSubstance>> watchRecentIntakes({required int limit}) {
    final query =
        select(intakes).join([
            innerJoin(substances, substances.id.equalsExp(intakes.substanceId)),
          ])
          ..where(intakes.deletedAt.isNull())
          ..orderBy([OrderingTerm.desc(intakes.takenAt)])
          ..limit(limit);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (
            intake: row.readTable(intakes),
            substance: row.readTable(substances),
          ),
      ],
    );
  }
}
