import 'package:drift/drift.dart';

import '../../core/db/database.dart';

typedef DailyTotal = ({
  /// Local calendar day at the moment of intake, `YYYY-MM-DD`.
  String day,
  String substanceId,
  double total,
  int count,
});

extension AnalyticsQueries on AppDatabase {
  /// Sums per local day, where "local" is the phone's offset when the intake
  /// happened, so travelling does not shift past entries across midnight.
  Stream<List<DailyTotal>> watchDailyTotals({required DateTime since}) {
    return customSelect(
      '''
      SELECT strftime('%Y-%m-%d', taken_at + tz_offset_min * 60, 'unixepoch') AS day,
             substance_id, SUM(amount) AS total, COUNT(*) AS count
      FROM intakes
      WHERE deleted_at IS NULL AND taken_at >= ?
      GROUP BY day, substance_id
      ORDER BY day
      ''',
      variables: [Variable.withDateTime(since)],
      readsFrom: {intakes},
    ).watch().map(
      (rows) => [
        for (final row in rows)
          (
            day: row.read<String>('day'),
            substanceId: row.read<String>('substance_id'),
            total: row.read<double>('total'),
            count: row.read<int>('count'),
          ),
      ],
    );
  }
}
