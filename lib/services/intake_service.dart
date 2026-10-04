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

  /// Changes the time and dose of [before] and returns whether anything
  /// changed. [wallTime] is read by its fields as the wall-clock time in the
  /// zone [before] was logged in, so the intake keeps its offset and shows
  /// exactly the picked time. A null [wallTime] means now, and a future time
  /// is clamped to now; both take the device's current offset, as [log] does.
  Future<bool> edit(
    Intake before, {
    required DateTime? wallTime,
    required double? amount,
  }) async {
    final now = _clock().toLocal();
    var takenAt = now;
    var offsetMin = now.timeZoneOffset.inMinutes;
    if (wallTime != null) {
      final w = wallTime;
      final picked = DateTime.utc(
        w.year,
        w.month,
        w.day,
        w.hour,
        w.minute,
        w.second,
      ).subtract(Duration(minutes: before.tzOffsetMin));
      if (!picked.isAfter(now)) {
        takenAt = picked;
        offsetMin = before.tzOffsetMin;
      }
    }
    if (takenAt.isAtSameMomentAs(before.takenAt) &&
        offsetMin == before.tzOffsetMin &&
        amount == before.amount) {
      return false;
    }
    await _write(before.id, takenAt, offsetMin, amount);
    return true;
  }

  /// Puts back the time and dose [before] had, undoing [edit].
  Future<void> revert(Intake before) =>
      _write(before.id, before.takenAt, before.tzOffsetMin, before.amount);

  Future<void> _write(
    String id,
    DateTime takenAt,
    int offsetMin,
    double? amount,
  ) => (db.update(db.intakes)..where((i) => i.id.equals(id))).write(
    IntakesCompanion(
      takenAt: Value(takenAt),
      tzOffsetMin: Value(offsetMin),
      amount: Value(amount),
      updatedAt: Value(_clock()),
    ),
  );

  Future<void> delete(String id) => _setDeletedAt(id, _clock());

  Future<void> restore(String id) => _setDeletedAt(id, null);

  Future<void> _setDeletedAt(String id, DateTime? value) =>
      (db.update(db.intakes)..where((i) => i.id.equals(id))).write(
        IntakesCompanion(deletedAt: Value(value), updatedAt: Value(_clock())),
      );
}
