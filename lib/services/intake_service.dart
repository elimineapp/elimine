import 'package:drift/drift.dart';

import '../core/db/database.dart';

/// The single write path for intakes. The UI and, later, the home-screen
/// widget callback both go through here.
class IntakeService {
  IntakeService(this.db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;

  /// Logs an intake and returns its id. A null [amount] records the intake
  /// without a dose. [takenAt] defaults to now; a future time is clamped to
  /// now.
  Future<String> log({
    required String substanceId,
    required double? amount,
    DateTime? takenAt,
  }) async {
    final now = _clock();
    final at = (takenAt == null || takenAt.isAfter(now) ? now : takenAt)
        .toLocal();
    final id = newId();
    await db
        .into(db.intakes)
        .insert(
          IntakesCompanion.insert(
            id: Value(id),
            substanceId: substanceId,
            amount: Value(amount),
            takenAt: at,
            tzOffsetMin: at.timeZoneOffset.inMinutes,
          ),
        );
    return id;
  }

  Future<void> delete(String id) => _setDeletedAt(id, _clock());

  Future<void> restore(String id) => _setDeletedAt(id, null);

  Future<void> _setDeletedAt(String id, DateTime? value) =>
      (db.update(db.intakes)..where((i) => i.id.equals(id))).write(
        IntakesCompanion(deletedAt: Value(value), updatedAt: Value(_clock())),
      );
}
