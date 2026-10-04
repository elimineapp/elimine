// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:elimine/core/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // v2 makes intakes.amount nullable by rebuilding the table; every row of
  // every table must come through unchanged.
  test('migration from v1 to v2 does not corrupt data', () async {
    const created = 1759500000;
    final oldSubstancesData = [
      v1.SubstancesData(
        id: 's1',
        name: 'Caffeine',
        unit: 'mg',
        color: 'blue',
        icon: 'coffee',
        sortOrder: 0,
        createdAt: created,
      ),
      v1.SubstancesData(
        id: 's2',
        name: 'Old',
        unit: 'g',
        color: 'red',
        icon: 'pill',
        sortOrder: 1,
        archivedAt: created + 10,
        createdAt: created,
      ),
    ];
    final expectedNewSubstancesData = [
      for (final s in oldSubstancesData)
        v2.SubstancesData(
          id: s.id,
          name: s.name,
          unit: s.unit,
          color: s.color,
          icon: s.icon,
          sortOrder: s.sortOrder,
          archivedAt: s.archivedAt,
          createdAt: s.createdAt,
        ),
    ];

    final oldDosesData = [
      v1.DosesData(id: 'd1', substanceId: 's1', amount: 100, sortOrder: 0),
      v1.DosesData(id: 'd2', substanceId: 's1', amount: 0.5, sortOrder: 1),
    ];
    final expectedNewDosesData = [
      for (final d in oldDosesData)
        v2.DosesData(
          id: d.id,
          substanceId: d.substanceId,
          amount: d.amount,
          sortOrder: d.sortOrder,
        ),
    ];

    final oldIntakesData = [
      v1.IntakesData(
        id: 'i1',
        substanceId: 's1',
        amount: 100,
        takenAt: created + 3600,
        tzOffsetMin: 600,
        createdAt: created + 3600,
        updatedAt: created + 3600,
      ),
      v1.IntakesData(
        id: 'i2',
        substanceId: 's2',
        amount: 1.25,
        takenAt: created + 7200,
        tzOffsetMin: -300,
        createdAt: created + 7200,
        updatedAt: created + 7300,
        deletedAt: created + 7300,
      ),
    ];
    final expectedNewIntakesData = [
      for (final i in oldIntakesData)
        v2.IntakesData(
          id: i.id,
          substanceId: i.substanceId,
          amount: i.amount,
          takenAt: i.takenAt,
          tzOffsetMin: i.tzOffsetMin,
          createdAt: i.createdAt,
          updatedAt: i.updatedAt,
          deletedAt: i.deletedAt,
        ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.substances, oldSubstancesData);
        batch.insertAll(oldDb.doses, oldDosesData);
        batch.insertAll(oldDb.intakes, oldIntakesData);
      },
      validateItems: (newDb) async {
        expect(
          await newDb.select(newDb.substances).get(),
          expectedNewSubstancesData,
        );
        expect(await newDb.select(newDb.doses).get(), expectedNewDosesData);
        expect(await newDb.select(newDb.intakes).get(), expectedNewIntakesData);
      },
    );
  });
}
