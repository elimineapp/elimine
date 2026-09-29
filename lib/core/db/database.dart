import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

export 'tables.dart' show newId;

part 'database.g.dart';

@DriftDatabase(tables: [Substances, Doses, Intakes])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  static QueryExecutor _open() => driftDatabase(name: 'elimine');

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // The home-screen widget will write through a second connection from a
      // background engine; WAL plus a busy timeout lets both coexist.
      await customSelect('PRAGMA journal_mode = WAL').get();
      await customStatement('PRAGMA busy_timeout = 5000');
    },
  );
}
