import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/db/database.dart';
import '../core/db/queries.dart';
import '../features/analytics/analytics_queries.dart';
import '../features/backup/backup_files.dart';
import '../features/backup/backup_service.dart';
import '../services/intake_service.dart';
import '../services/substance_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final intakeServiceProvider = Provider<IntakeService>(
  (ref) => IntakeService(ref.watch(databaseProvider)),
);

final substanceServiceProvider = Provider<SubstanceService>(
  (ref) => SubstanceService(ref.watch(databaseProvider)),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider)),
);

final backupFilesProvider = Provider<BackupFiles>(
  (ref) => const SystemBackupFiles(),
);

/// Version name of the installed build, e.g. `0.1.0`.
final appVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);

final substancesProvider = StreamProvider<List<SubstanceWithLast>>(
  (ref) => ref.watch(databaseProvider).watchSubstancesWithLast(),
);

final archivedSubstancesProvider = StreamProvider<List<SubstanceWithCount>>(
  (ref) => ref.watch(databaseProvider).watchArchivedSubstances(),
);

final recentIntakesProvider = StreamProvider<List<IntakeWithSubstance>>(
  (ref) => ref.watch(databaseProvider).watchRecentIntakes(),
);

final substanceProvider = StreamProvider.family<Substance?, String>(
  (ref, id) => ref.watch(databaseProvider).watchSubstance(id),
);

final dosesProvider = StreamProvider.family<List<Dose>, String>(
  (ref, id) => ref.watch(databaseProvider).watchDoses(id),
);

final substanceIntakesProvider = StreamProvider.family<List<Intake>, String>(
  (ref, id) => ref.watch(databaseProvider).watchIntakesFor(id),
);

final allSubstancesProvider = StreamProvider<List<Substance>>(
  (ref) => ref.watch(databaseProvider).watchAllSubstances(),
);

typedef DailyTotalsQuery = ({DateTime? since, String? substanceId});

final dailyTotalsProvider =
    StreamProvider.family<List<DailyTotal>, DailyTotalsQuery>(
      (ref, q) => ref
          .watch(databaseProvider)
          .watchDailyTotals(since: q.since, substanceId: q.substanceId),
    );
