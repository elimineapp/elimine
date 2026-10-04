import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:elimine/app/providers.dart';
import 'package:elimine/core/db/database.dart';
import 'package:elimine/features/backup/backup_files.dart';
import 'package:elimine/features/backup/backup_format.dart';
import 'package:elimine/features/backup/settings_screen.dart';
import 'package:elimine/l10n/app_localizations.dart';
import 'package:elimine/services/intake_service.dart';
import 'package:elimine/services/settings_service.dart';
import 'package:elimine/services/substance_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the system dialogs: [toOpen] is what the user picks (null
/// cancels), [saveAccepted] whether they confirm saving.
class FakeBackupFiles implements BackupFiles {
  String? toOpen;
  bool saveAccepted = true;
  String? savedName;
  String? savedContent;

  @override
  Future<bool> save(String fileName, String content) async {
    if (!saveAccepted) return false;
    savedName = fileName;
    savedContent = content;
    return true;
  }

  @override
  Future<String?> open() async => toOpen;
}

void main() {
  final now = DateTime(2026, 10, 4, 14);
  late AppDatabase db;
  late FakeBackupFiles files;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    files = FakeBackupFiles();
  });

  tearDown(() => db.close());

  /// Lets database work started by the UI finish in real time, then settles.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          backupFilesProvider.overrideWithValue(files),
          appVersionProvider.overrideWith((ref) async => '0.1.0'),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(clock: () => now),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<int> count(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.intakes).get()))!.length;

  String backupWith(int intakes) => encodeBackup([
    BackupSubstance(
      id: '01999b5e-7c2a-7d3e-9f10-2b4c6d8e0a11',
      name: 'Coffee',
      intakes: [
        for (var i = 0; i < intakes; i++)
          BackupIntake(
            id: '01999b5e-7c2a-7d3e-9f10-2b4c6d8e0b${i.toString().padLeft(2, '0')}',
            takenAt: DateTime.utc(2026, 9, 1 + i, 8),
            tzOffsetMin: 180,
          ),
      ],
    ),
  ], now: now);

  testWidgets('export saves a dated file and confirms', (tester) async {
    await tester.runAsync(() async {
      final id = await SubstanceService(db).create((
        name: 'Tea',
        unit: '',
        color: 'aqua',
        icon: 'leaf',
        doses: const [],
      ));
      await IntakeService(db).log(substanceId: id, amount: null);
    });
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('export')));
    await settle(tester);

    expect(files.savedName, 'elimine-2026-10-04.json');
    final [tea] = decodeBackup(files.savedContent!, now: DateTime.now());
    expect((tea.name, tea.intakes.length), ('Tea', 1));
    expect(find.text('Data exported'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelling the save dialog says nothing', (tester) async {
    files.saveAccepted = false;
    await pumpSettings(tester);
    await tester.tap(find.byKey(const Key('export')));
    await settle(tester);
    expect(find.text('Data exported'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('import previews, then adds on confirm', (tester) async {
    files.toOpen = backupWith(3);
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('import')));
    await settle(tester);
    expect(
      find.text('Will be added: 1 substance and 3 entries.'),
      findsOneWidget,
    );
    expect(await count(tester), 0);

    await tester.tap(find.byKey(const Key('confirmImport')));
    await settle(tester);
    expect(await count(tester), 3);
    expect(find.text('Imported: 1 substance and 3 entries'), findsOneWidget);

    // The same file again: nothing new, nothing to confirm.
    await tester.tap(find.byKey(const Key('import')));
    await settle(tester);
    expect(
      find.text('Everything in this file is already here.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('confirmImport')), findsNothing);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(await count(tester), 3);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelling the preview writes nothing', (tester) async {
    files.toOpen = backupWith(2);
    await pumpSettings(tester);
    await tester.tap(find.byKey(const Key('import')));
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(await count(tester), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an invalid file shows where it is broken', (tester) async {
    files.toOpen = backupWith(1).replaceFirst('+03:00', '');
    await pumpSettings(tester);
    await tester.tap(find.byKey(const Key('import')));
    await settle(tester);

    expect(find.text("Can't import this file"), findsOneWidget);
    expect(
      find.textContaining('substances[0].intakes[0].takenAt'),
      findsOneWidget,
    );
    expect(await count(tester), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelling the file picker does nothing', (tester) async {
    await pumpSettings(tester);
    await tester.tap(find.byKey(const Key('import')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the last row shows the installed version', (tester) async {
    await pumpSettings(tester);
    final last = tester.widgetList<ListTile>(find.byType(ListTile)).last;
    expect(last.key, const Key('version'));
    expect(
      find.descendant(
        of: find.byKey(const Key('version')),
        matching: find.text('Version'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('version')),
        matching: find.text('0.1.0'),
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('week starts on Monday until Sunday is chosen', (tester) async {
    await pumpSettings(tester);
    final row = find.byKey(const Key('weekStart'));
    expect(
      find.descendant(of: row, matching: find.text('Monday')),
      findsOneWidget,
    );

    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('weekStart-${DateTime.sunday}')));
    await settle(tester);

    expect(
      find.descendant(of: row, matching: find.text('Sunday')),
      findsOneWidget,
    );
    final saved = await tester.runAsync(
      () => SettingsService(db).watchWeekStart().first,
    );
    expect(saved, DateTime.sunday);
    await tester.pumpWidget(const SizedBox());
  });
}
