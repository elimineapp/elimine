import 'package:drift/drift.dart';

import '../../core/db/database.dart';

typedef DailyTotal = ({
  /// Local calendar day at the moment of intake, `YYYY-MM-DD`.
  String day,
  String substanceId,

  /// Sum of the known doses; intakes without a dose add nothing.
  double total,
  int count,

  /// Intakes with a dose; `count - dosed` had none.
  int dosed,
});

extension AnalyticsQueries on AppDatabase {
  /// Sums per local day, where "local" is the phone's offset when the intake
  /// happened, so travelling does not shift past entries across midnight.
  /// [since] is compared against the UTC instant, so callers pass a day of
  /// margin and trim by `day`.
  Stream<List<DailyTotal>> watchDailyTotals({
    DateTime? since,
    String? substanceId,
  }) {
    return customSelect(
      '''
      SELECT strftime('%Y-%m-%d', taken_at + tz_offset_min * 60, 'unixepoch') AS day,
             substance_id, COALESCE(SUM(amount), 0) AS total, COUNT(*) AS count,
             COUNT(amount) AS dosed
      FROM intakes
      WHERE deleted_at IS NULL
        AND (?1 IS NULL OR taken_at >= ?1)
        AND (?2 IS NULL OR substance_id = ?2)
      GROUP BY day, substance_id
      ORDER BY day
      ''',
      variables: [Variable<DateTime>(since), Variable<String>(substanceId)],
      readsFrom: {intakes},
    ).watch().map(
      (rows) => [
        for (final row in rows)
          (
            day: row.read<String>('day'),
            substanceId: row.read<String>('substance_id'),
            total: row.read<double>('total'),
            count: row.read<int>('count'),
            dosed: row.read<int>('dosed'),
          ),
      ],
    );
  }

  /// Every substance, archived ones included: their past intakes still show
  /// up in analytics.
  Stream<List<Substance>> watchAllSubstances() => (select(
    substances,
  )..orderBy([(s) => OrderingTerm.asc(s.sortOrder)])).watch();
}
