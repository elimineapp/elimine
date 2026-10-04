import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'database.steps.dart';
import 'tables.dart';

export 'tables.dart' show newId;

part 'database.g.dart';

@DriftDatabase(tables: [Substances, Doses, Intakes])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  static QueryExecutor _open() => driftDatabase(name: 'elimine');

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      // SQLite cannot drop NOT NULL in place; alterTable rebuilds the table
      // and copies every row.
      from1To2: (m, schema) => m.alterTable(TableMigration(schema.intakes)),
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // Deleting a substance must not leave its data readable in free pages.
      await customStatement('PRAGMA secure_delete = ON');
      // The home-screen widget will write through a second connection from a
      // background engine; WAL plus a busy timeout lets both coexist.
      await customSelect('PRAGMA journal_mode = WAL').get();
      await customStatement('PRAGMA busy_timeout = 5000');
    },
  );
}
