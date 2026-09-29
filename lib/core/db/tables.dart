import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Time-ordered UUIDv7, so ids sort roughly by creation time.
String newId() => _uuid.v7();

@DataClassName('Substance')
class Substances extends Table {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get name => text()();

  /// Free text ("mg", "tab", "puffs"). Amounts are plain numbers in this unit
  /// and are never converted.
  TextColumn get unit => text()();

  /// Keys into `substanceColors` / `substanceIcons` in appearance.dart.
  TextColumn get color => text()();
  TextColumn get icon => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Frequent doses offered as chips on the substance screen.
@DataClassName('Dose')
class Doses extends Table {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get substanceId => text().references(Substances, #id)();
  RealColumn get amount => real()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Intake')
@TableIndex(name: 'intakes_taken_at', columns: {#takenAt})
@TableIndex(
  name: 'intakes_substance_taken_at',
  columns: {#substanceId, #takenAt},
)
class Intakes extends Table {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get substanceId => text().references(Substances, #id)();
  RealColumn get amount => real()();

  /// Stored as unix seconds (UTC). Together with [tzOffsetMin] this gives the
  /// local wall-clock time at the moment of intake, independent of where the
  /// phone is now.
  DateTimeColumn get takenAt => dateTime()();
  IntColumn get tzOffsetMin => integer()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
