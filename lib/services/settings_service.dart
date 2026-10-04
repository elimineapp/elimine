import '../core/db/database.dart';

/// Device preferences stored in the `settings` table.
class SettingsService {
  SettingsService(this.db);

  final AppDatabase db;

  static const _weekStart = 'weekStart';

  /// The first day of the week as a [DateTime.weekday]: Monday unless the
  /// user chose Sunday.
  Stream<int> watchWeekStart() =>
      (db.select(
        db.settings,
      )..where((s) => s.key.equals(_weekStart))).watchSingleOrNull().map(
        (row) => row?.value == 'sunday' ? DateTime.sunday : DateTime.monday,
      );

  Future<void> setWeekStart(int weekday) {
    assert(weekday == DateTime.monday || weekday == DateTime.sunday);
    return db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: _weekStart,
            value: weekday == DateTime.sunday ? 'sunday' : 'monday',
          ),
        );
  }
}
