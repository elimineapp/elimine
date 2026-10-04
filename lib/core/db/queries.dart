import 'package:drift/drift.dart';

import 'database.dart';

typedef SubstanceWithLast = ({Substance substance, Intake? last});
typedef IntakeWithSubstance = ({Intake intake, Substance substance});
typedef SubstanceWithCount = ({Substance substance, int intakes});

extension SharedQueries on AppDatabase {
  /// Active substances with their latest intake, in the user's order.
  Stream<List<SubstanceWithLast>> watchSubstancesWithLast() {
    final latest = alias(intakes, 'latest');
    final latestId = subqueryExpression<String>(
      selectOnly(intakes)
        ..addColumns([intakes.id])
        ..where(
          intakes.substanceId.equalsExp(substances.id) &
              intakes.deletedAt.isNull(),
        )
        ..orderBy([OrderingTerm.desc(intakes.takenAt)])
        ..limit(1),
    );
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

  /// Archived substances with their visible intake counts, in the user's
  /// order.
  Stream<List<SubstanceWithCount>> watchArchivedSubstances() {
    final count = intakes.id.count();
    final query =
        select(substances).join([
            leftOuterJoin(
              intakes,
              intakes.substanceId.equalsExp(substances.id) &
                  intakes.deletedAt.isNull(),
              useColumns: false,
            ),
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
          (substance: row.readTable(substances), intakes: row.read(count) ?? 0),
      ],
    );
  }

  Stream<List<IntakeWithSubstance>> watchRecentIntakes({int limit = 10}) {
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
