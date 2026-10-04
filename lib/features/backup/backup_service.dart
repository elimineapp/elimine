import 'package:drift/drift.dart';

import '../../core/appearance.dart';
import '../../core/db/database.dart';
import 'backup_format.dart';

/// What an import would do, shown to the user before anything is written.
class ImportPlan {
  const ImportPlan({
    required this.substances,
    required this.newSubstances,
    required this.newIntakes,
    required this.presentSubstances,
    required this.presentIntakes,
  });

  final List<BackupSubstance> substances;
  final int newSubstances;
  final int newIntakes;
  final int presentSubstances;
  final int presentIntakes;

  bool get addsNothing => newSubstances == 0 && newIntakes == 0;
}

/// Export to and import from the backup format. Import only adds records
/// whose ids are missing; existing ones are never changed ("the database
/// wins"), so importing the same file twice is harmless.
class BackupService {
  BackupService(this.db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;

  /// Every substance (archived included) with its doses and non-deleted
  /// intakes, in home-screen order, as backup JSON.
  Future<String> export() async {
    final substances =
        await (db.select(db.substances)..orderBy([
              (s) => OrderingTerm.asc(s.sortOrder),
              (s) => OrderingTerm.asc(s.id),
            ]))
            .get();
    final doses = await (db.select(
      db.doses,
    )..orderBy([(d) => OrderingTerm.asc(d.sortOrder)])).get();
    final intakes =
        await (db.select(db.intakes)
              ..where((i) => i.deletedAt.isNull())
              ..orderBy([(i) => OrderingTerm.asc(i.takenAt)]))
            .get();

    return encodeBackup([
      for (final s in substances)
        BackupSubstance(
          id: s.id,
          name: s.name,
          unit: s.unit,
          color: s.color,
          icon: s.icon,
          archived: s.archivedAt != null,
          doses: [
            for (final d in doses)
              if (d.substanceId == s.id) d.amount,
          ],
          intakes: [
            for (final i in intakes)
              if (i.substanceId == s.id)
                BackupIntake(
                  id: i.id,
                  takenAt: i.takenAt.toUtc(),
                  tzOffsetMin: i.tzOffsetMin,
                  amount: i.amount,
                ),
          ],
        ),
    ], now: _clock());
  }

  /// Counts what importing [substances] would add and skip.
  Future<ImportPlan> plan(List<BackupSubstance> substances) async {
    final (substanceIds, intakeIds) = await _existingIds();
    var newSubstances = 0, newIntakes = 0, intakeCount = 0;
    for (final s in substances) {
      if (!substanceIds.contains(s.id)) newSubstances++;
      intakeCount += s.intakes.length;
      newIntakes += s.intakes.where((i) => !intakeIds.contains(i.id)).length;
    }
    return ImportPlan(
      substances: substances,
      newSubstances: newSubstances,
      newIntakes: newIntakes,
      presentSubstances: substances.length - newSubstances,
      presentIntakes: intakeCount - newIntakes,
    );
  }

  /// Adds the missing substances (after the existing ones, with their doses)
  /// and the missing intakes, all in one transaction.
  Future<void> apply(ImportPlan plan) => db.transaction(() async {
    final (substanceIds, intakeIds) = await _existingIds();
    final now = _clock();
    final maxOrder = db.substances.sortOrder.max();
    var order =
        (await (db.selectOnly(
          db.substances,
        )..addColumns([maxOrder])).getSingle()).read(maxOrder) ??
        -1;
    final usedColors = {
      for (final s in await (db.select(
        db.substances,
      )..where((s) => s.archivedAt.isNull())).get())
        s.color,
    };

    for (final s in plan.substances) {
      if (substanceIds.add(s.id)) {
        final color =
            s.color ??
            substanceColors.keys.firstWhere(
              (c) => !usedColors.contains(c),
              orElse: () => substanceColors.keys.first,
            );
        if (!s.archived) usedColors.add(color);
        await db
            .into(db.substances)
            .insert(
              SubstancesCompanion.insert(
                id: Value(s.id),
                name: s.name,
                unit: s.unit,
                color: color,
                icon: s.icon ?? substanceIcons.keys.first,
                sortOrder: Value(++order),
                archivedAt: Value(s.archived ? now : null),
                createdAt: Value(now),
              ),
            );
        for (final (i, amount) in ({...s.doses}.toList()..sort()).indexed) {
          await db
              .into(db.doses)
              .insert(
                DosesCompanion.insert(
                  substanceId: s.id,
                  amount: amount,
                  sortOrder: Value(i),
                ),
              );
        }
      }
      for (final i in s.intakes) {
        if (!intakeIds.add(i.id)) continue;
        await db
            .into(db.intakes)
            .insert(
              IntakesCompanion.insert(
                id: Value(i.id),
                substanceId: s.id,
                amount: Value(i.amount),
                takenAt: i.takenAt,
                tzOffsetMin: i.tzOffsetMin,
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }
    }
  });

  /// Soft-deleted intakes count as present: their ids stay taken.
  Future<(Set<String>, Set<String>)> _existingIds() async {
    final substanceIds =
        await (db.selectOnly(db.substances)..addColumns([db.substances.id]))
            .map((r) => r.read(db.substances.id)!)
            .get();
    final intakeIds = await (db.selectOnly(
      db.intakes,
    )..addColumns([db.intakes.id])).map((r) => r.read(db.intakes.id)!).get();
    return (substanceIds.toSet(), intakeIds.toSet());
  }
}
