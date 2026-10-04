import 'package:drift/drift.dart';

import '../core/db/database.dart';

/// What the substance form edits. Doses are saved as a whole list.
typedef SubstanceDraft = ({
  String name,
  String unit,
  String color,
  String icon,
  List<double> doses,
});

class SubstanceService {
  SubstanceService(this.db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;

  /// Creates a substance at the end of the home grid and returns its id.
  Future<String> create(SubstanceDraft draft) => db.transaction(() async {
    final maxOrder = db.substances.sortOrder.max();
    final last = await (db.selectOnly(
      db.substances,
    )..addColumns([maxOrder])).map((row) => row.read(maxOrder)).getSingle();

    final id = newId();
    await db
        .into(db.substances)
        .insert(
          SubstancesCompanion.insert(
            id: Value(id),
            name: draft.name.trim(),
            unit: draft.unit.trim(),
            color: draft.color,
            icon: draft.icon,
            sortOrder: Value((last ?? -1) + 1),
          ),
        );
    await _replaceDoses(id, draft.doses);
    return id;
  });

  Future<void> update(String id, SubstanceDraft draft) =>
      db.transaction(() async {
        await (db.update(db.substances)..where((s) => s.id.equals(id))).write(
          SubstancesCompanion(
            name: Value(draft.name.trim()),
            unit: Value(draft.unit.trim()),
            color: Value(draft.color),
            icon: Value(draft.icon),
          ),
        );
        await _replaceDoses(id, draft.doses);
      });

  /// Hides the substance from the home screen; its intakes stay in history.
  Future<void> archive(String id) =>
      (db.update(db.substances)..where((s) => s.id.equals(id))).write(
        SubstancesCompanion(archivedAt: Value(_clock())),
      );

  /// Puts an archived substance back on the home grid, in its old place.
  Future<void> restore(String id) =>
      (db.update(db.substances)..where((s) => s.id.equals(id))).write(
        const SubstancesCompanion(archivedAt: Value(null)),
      );

  /// Removes the substance with its doses and every intake, soft-deleted ones
  /// included. Permanent: with `secure_delete` on, SQLite zeroes the freed
  /// content, and the checkpoint drops WAL frames that still hold it.
  Future<void> delete(String id) async {
    await db.transaction(() async {
      await (db.delete(
        db.intakes,
      )..where((i) => i.substanceId.equals(id))).go();
      await (db.delete(db.doses)..where((d) => d.substanceId.equals(id))).go();
      await (db.delete(db.substances)..where((s) => s.id.equals(id))).go();
    });
    await db.customSelect('PRAGMA wal_checkpoint(TRUNCATE)').get();
  }

  /// Doses are not referenced by intakes, so they can be rewritten outright.
  Future<void> _replaceDoses(String substanceId, List<double> amounts) async {
    await (db.delete(
      db.doses,
    )..where((d) => d.substanceId.equals(substanceId))).go();
    final unique = {...amounts}.toList()..sort();
    for (final (i, amount) in unique.indexed) {
      await db
          .into(db.doses)
          .insert(
            DosesCompanion.insert(
              substanceId: substanceId,
              amount: amount,
              sortOrder: Value(i),
            ),
          );
    }
  }
}
