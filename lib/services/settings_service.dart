import 'package:drift/drift.dart' show StringExpressionOperators;
import 'package:flutter/material.dart' show Locale, ThemeMode;

import '../core/db/database.dart';
import '../l10n/app_localizations.dart';

/// The interface language and theme the user chose; a null [locale] and
/// [ThemeMode.system] follow the device.
typedef Preferences = ({Locale? locale, ThemeMode themeMode});

/// The stored app lock: on exactly when [pin] (an encoded hash) is set.
typedef LockSettings = ({
  String? pin,
  int pinLength,
  bool biometric,
  Duration lockAfter,
  int failures,
  DateTime? blockedUntil,
});

/// Device preferences stored in the `settings` table.
class SettingsService {
  SettingsService(this.db);

  final AppDatabase db;

  static const _weekStart = 'weekStart';
  static const _sheetExpanded = 'sheetExpanded';
  static const _language = 'language';
  static const _themeMode = 'themeMode';
  static const _lockPrefix = 'appLock.';
  static const _lockPin = '${_lockPrefix}pin';
  static const _lockPinLength = '${_lockPrefix}pinLength';
  static const _lockBiometric = '${_lockPrefix}biometric';
  static const _lockAfter = '${_lockPrefix}after';
  static const _lockFailures = '${_lockPrefix}failures';
  static const _lockBlockedUntil = '${_lockPrefix}blockedUntil';

  static const defaultLockAfter = Duration(minutes: 1);

  /// The first day of the week as a [DateTime.weekday]: Monday unless the
  /// user chose Sunday.
  Stream<int> watchWeekStart() =>
      (db.select(
        db.settings,
      )..where((s) => s.key.equals(_weekStart))).watchSingleOrNull().map(
        (row) => row?.value == 'sunday' ? DateTime.sunday : DateTime.monday,
      );

  Future<void> setWeekStart(int weekday) {
    assert(weekday == DateTime.monday || weekday == DateTime.sunday);
    return db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: _weekStart,
            value: weekday == DateTime.sunday ? 'sunday' : 'monday',
          ),
        );
  }

  /// Whether a substance screen has ever been expanded on this device; until
  /// then, opening one hints that it can be pulled up.
  Stream<bool> watchSheetExpanded() =>
      (db.select(db.settings)..where((s) => s.key.equals(_sheetExpanded)))
          .watchSingleOrNull()
          .map((row) => row?.value == 'true');

  Future<void> setSheetExpanded() => db
      .into(db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: _sheetExpanded, value: 'true'),
      );

  /// The chosen interface language, or null to follow the device. A language
  /// the app no longer supports also follows the device.
  Stream<Locale?> watchLocale() => _watch(_language).map(_locale);

  /// Null follows the device again.
  Future<void> setLocale(Locale? locale) =>
      _set(_language, locale?.languageCode);

  Stream<ThemeMode> watchThemeMode() => _watch(_themeMode).map(_theme);

  Future<void> setThemeMode(ThemeMode mode) =>
      _set(_themeMode, mode == ThemeMode.system ? null : mode.name);

  /// Both choices at once, for the app's first frame.
  Future<Preferences> readPreferences() async {
    final rows = await (db.select(
      db.settings,
    )..where((s) => s.key.isIn([_language, _themeMode]))).get();
    String? value(String key) =>
        rows.where((r) => r.key == key).firstOrNull?.value;
    return (
      locale: _locale(value(_language)),
      themeMode: _theme(value(_themeMode)),
    );
  }

  /// Everything about the app lock at once, for the first frame and for the
  /// lock itself.
  Future<LockSettings> readLock() async {
    final rows = await (db.select(
      db.settings,
    )..where((s) => s.key.like('$_lockPrefix%'))).get();
    final values = {for (final r in rows) r.key: r.value};
    final after = int.tryParse(values[_lockAfter] ?? '');
    final blockedUntil = values[_lockBlockedUntil];
    return (
      pin: values[_lockPin],
      pinLength: int.tryParse(values[_lockPinLength] ?? '') ?? 0,
      biometric: values[_lockBiometric] == 'true',
      lockAfter: after == null ? defaultLockAfter : Duration(seconds: after),
      failures: int.tryParse(values[_lockFailures] ?? '') ?? 0,
      blockedUntil: blockedUntil == null
          ? null
          : DateTime.tryParse(blockedUntil)?.toLocal(),
    );
  }

  /// Turns the lock on, or replaces its PIN, with an encoded hash.
  Future<void> setLockPin(String encoded, int length) =>
      db.transaction(() async {
        await _set(_lockPin, encoded);
        await _set(_lockPinLength, '$length');
      });

  Future<void> setLockBiometric(bool on) =>
      _set(_lockBiometric, on ? 'true' : null);

  Future<void> setLockAfter(Duration after) =>
      _set(_lockAfter, after == defaultLockAfter ? null : '${after.inSeconds}');

  /// Wrong PINs in a row and until when input is refused; 0 and null clear
  /// them.
  Future<void> setLockFailures(int failures, DateTime? blockedUntil) =>
      db.transaction(() async {
        await _set(_lockFailures, failures == 0 ? null : '$failures');
        await _set(_lockBlockedUntil, blockedUntil?.toUtc().toIso8601String());
      });

  /// Turns the lock off and forgets everything about it.
  Future<void> clearLock() =>
      (db.delete(db.settings)..where((s) => s.key.like('$_lockPrefix%'))).go();

  static Locale? _locale(String? code) => AppLocalizations.supportedLocales
      .where((l) => l.languageCode == code)
      .firstOrNull;

  static ThemeMode _theme(String? name) => switch (name) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Stream<String?> _watch(String key) =>
      (db.select(db.settings)..where((s) => s.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  /// Stores [value] under [key]; null deletes it, which means the default.
  Future<void> _set(String key, String? value) => value == null
      ? (db.delete(db.settings)..where((s) => s.key.equals(key))).go()
      : db
            .into(db.settings)
            .insertOnConflictUpdate(
              SettingsCompanion.insert(key: key, value: value),
            );
}
