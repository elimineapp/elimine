import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/database.dart';
import '../core/db/queries.dart';
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

final substancesProvider = StreamProvider<List<SubstanceWithLast>>(
  (ref) => ref.watch(databaseProvider).watchSubstancesWithLast(),
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
