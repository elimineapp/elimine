import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lock_fakes.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('elimine_'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// Whether [needle] appears in any of the database's files.
  bool onDisk(String needle) {
    final bytes = utf8.encode(needle);
    for (final file in dir.listSync().whereType<File>()) {
      final content = file.readAsBytesSync();
      outer:
      for (var i = 0; i + bytes.length <= content.length; i++) {
        for (var j = 0; j < bytes.length; j++) {
          if (content[i + j] != bytes[j]) continue outer;
        }
        return true;
      }
    }
    return false;
  }

  test('a deleted substance leaves no trace in the database files', () async {
    final db = AppDatabase(NativeDatabase(File('${dir.path}/elimine.sqlite')));
    final substances = SubstanceService(db);
    final keep = await substances.create((
      name: 'Kept',
      unit: 'mg',
      color: 'blue',
      icon: 'pill',
      doses: const [],
    ));
    final gone = await substances.create((
      name: 'Zebra-test',
      unit: 'zebra-unit',
      color: 'red',
      icon: 'pill',
      doses: const [7],
    ));
    for (var i = 0; i < 20; i++) {
      await IntakeService(db).log(substanceId: gone, amount: 7);
    }
    await IntakeService(db).log(substanceId: keep, amount: 1);
    // Push everything into the main file, as a long-running app would.
    await db.customSelect('PRAGMA wal_checkpoint(TRUNCATE)').get();
    expect(onDisk('Zebra-test'), isTrue);

    await substances.delete(gone);
    await db.close();

    expect(onDisk('Zebra-test'), isFalse);
    expect(onDisk('zebra-unit'), isFalse);
    expect(onDisk('Kept'), isTrue);
  });

  test('erasing after a forgotten PIN leaves no trace either', () async {
    final db = AppDatabase(NativeDatabase(File('${dir.path}/elimine.sqlite')));
    final gone = await SubstanceService(db).create((
      name: 'Zebra-test',
      unit: 'zebra-unit',
      color: 'red',
      icon: 'pill',
      doses: const [7],
    ));
    for (var i = 0; i < 20; i++) {
      await IntakeService(db).log(substanceId: gone, amount: 7);
    }
    await SettingsService(db).setLockPin(r'pbkdf2-sha256$1$AA==$AA==', 4);
    await db.customSelect('PRAGMA wal_checkpoint(TRUNCATE)').get();
    expect(onDisk('Zebra-test'), isTrue);

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialLockProvider.overrideWithValue(
          await SettingsService(db).readLock(),
        ),
        recentsWindowProvider.overrideWithValue(FakeRecentsWindow()),
      ],
    );
    await container.read(appLockProvider.notifier).eraseAll();
    container.dispose();
    await db.close();

    expect(onDisk('Zebra-test'), isFalse);
    expect(onDisk('zebra-unit'), isFalse);
    expect(onDisk('pbkdf2'), isFalse);
  });
}
