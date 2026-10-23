import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/settings_service.dart';
import 'biometrics.dart';

/// What the lock shows to the rest of the app. The PIN hash stays inside
/// [AppLock].
@immutable
class AppLockState {
  const AppLockState({
    required this.enabled,
    required this.locked,
    required this.pinLength,
    required this.biometric,
    required this.lockAfter,
    required this.failures,
    required this.blockedUntil,
  });

  final bool enabled;

  /// Whether only the lock screen may be shown.
  final bool locked;

  final int pinLength;
  final bool biometric;

  /// How long the app may stay in the background before it locks again.
  final Duration lockAfter;

  /// Wrong PINs in a row.
  final int failures;

  /// Until when PIN input is refused, if it is.
  final DateTime? blockedUntil;

  AppLockState copyWith({
    bool? locked,
    bool? biometric,
    Duration? lockAfter,
    int? failures,
    DateTime? Function()? blockedUntil,
  }) => AppLockState(
    enabled: enabled,
    locked: locked ?? this.locked,
    pinLength: pinLength,
    biometric: biometric ?? this.biometric,
    lockAfter: lockAfter ?? this.lockAfter,
    failures: failures ?? this.failures,
    blockedUntil: blockedUntil == null ? this.blockedUntil : blockedUntil(),
  );
}

enum PinCheck { right, wrong, blocked }

/// The "Lock after" choices.
const lockAfterOptions = [
  Duration.zero,
  Duration(minutes: 1),
  Duration(minutes: 5),
  Duration(minutes: 15),
];

/// The optional PIN and biometric lock: whether the app is locked, when it
/// locks again, and every change to the lock's settings.
class AppLock extends Notifier<AppLockState> {
  /// Wrong PINs allowed in a row before input is refused for a while.
  static const freeAttempts = 5;
  static const firstWait = Duration(seconds: 30);
  static const longestWait = Duration(hours: 1);

  String? _pin;
  DateTime? _hiddenAt;
  int _external = 0;

  SettingsService get _settings => ref.read(settingsServiceProvider);
  DateTime _now() => ref.read(clockProvider)();

  @override
  AppLockState build() {
    final stored = ref.read(initialLockProvider);
    _pin = stored.pin;
    if (_pin != null) {
      // Default is shown, so only a lock that is on needs the call.
      unawaited(ref.read(recentsWindowProvider).setHidden(true));
    }
    return _fromStored(stored, locked: _pin != null);
  }

  static AppLockState _fromStored(LockSettings s, {required bool locked}) =>
      AppLockState(
        enabled: s.pin != null,
        locked: locked,
        pinLength: s.pinLength,
        biometric: s.biometric,
        lockAfter: s.lockAfter,
        failures: s.failures,
        blockedUntil: s.blockedUntil,
      );

  Future<void> _reload({required bool locked}) async {
    final stored = await _settings.readLock();
    _pin = stored.pin;
    state = _fromStored(stored, locked: locked);
  }

  /// The app stopped being visible.
  void appHidden() {
    if (!state.enabled || state.locked || _external > 0) return;
    if (state.lockAfter == Duration.zero) {
      // Lock before leaving, so not even a frame of content is left behind.
      state = state.copyWith(locked: true);
    } else {
      _hiddenAt = _now();
    }
  }

  /// The app is visible again.
  void appShown() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (hiddenAt == null || !state.enabled || state.locked) return;
    if (_now().difference(hiddenAt) >= state.lockAfter) {
      state = state.copyWith(locked: true);
    }
  }

  /// Runs [work], which opens a system dialog of the app's own, such as
  /// saving a backup or the biometric prompt, without leaving the app
  /// counting as leaving it.
  Future<T> whileExternal<T>(Future<T> Function() work) async {
    _external++;
    try {
      return await work();
    } finally {
      _external--;
      _hiddenAt = null;
    }
  }

  /// Checks [pin] against the stored one, counting wrong ones and refusing
  /// input while they are throttled.
  Future<PinCheck> checkPin(String pin) async {
    final stored = _pin;
    if (stored == null) return PinCheck.wrong;
    final blockedUntil = state.blockedUntil;
    if (blockedUntil != null && _now().isBefore(blockedUntil)) {
      return PinCheck.blocked;
    }
    final hasher = ref.read(pinHasherProvider);
    if (await hasher.verify(pin, stored)) {
      await _resetFailures();
      if (hasher.needsRehash(stored)) {
        _pin = await hasher.hash(pin);
        await _settings.setLockPin(_pin!, pin.length);
      }
      return PinCheck.right;
    }
    final failures = state.failures + 1;
    final until = failures < freeAttempts ? null : _now().add(_wait(failures));
    await _settings.setLockFailures(failures, until);
    state = state.copyWith(failures: failures, blockedUntil: () => until);
    return PinCheck.wrong;
  }

  /// 30 s after the fifth wrong PIN in a row, doubling with each further
  /// one, up to an hour.
  static Duration _wait(int failures) {
    final doublings = min(failures - freeAttempts, 7);
    final wait = firstWait * pow(2, doublings).toInt();
    return wait > longestWait ? longestWait : wait;
  }

  Future<void> _resetFailures() async {
    if (state.failures == 0 && state.blockedUntil == null) return;
    await _settings.setLockFailures(0, null);
    state = state.copyWith(failures: 0, blockedUntil: () => null);
  }

  Future<PinCheck> unlockWithPin(String pin) async {
    final result = await checkPin(pin);
    if (result == PinCheck.right) state = state.copyWith(locked: false);
    return result;
  }

  /// Shows the biometric prompt when biometric unlock is on; a success
  /// resets wrong PINs too.
  Future<bool> checkBiometrics(BiometricPromptText text) async {
    if (!state.biometric) return false;
    final ok = await whileExternal(
      () => ref.read(biometricsProvider).authenticate(text),
    );
    if (ok) await _resetFailures();
    return ok;
  }

  Future<bool> unlockWithBiometrics(BiometricPromptText text) async {
    final ok = await checkBiometrics(text);
    if (ok) state = state.copyWith(locked: false);
    return ok;
  }

  /// Turns the lock on with [pin], or replaces the PIN of a lock that is on.
  /// Callers check the current PIN first.
  Future<void> setPin(String pin) async {
    final encoded = await ref.read(pinHasherProvider).hash(pin);
    final wasEnabled = state.enabled;
    if (!wasEnabled) await _settings.clearLock();
    await _settings.setLockPin(encoded, pin.length);
    await _reload(locked: false);
    if (!wasEnabled) await ref.read(recentsWindowProvider).setHidden(true);
  }

  /// Turns the lock off and forgets its settings. Callers check the PIN
  /// first.
  Future<void> disable() async {
    await _settings.clearLock();
    await _reload(locked: false);
    await ref.read(recentsWindowProvider).setHidden(false);
  }

  /// Turns biometric unlock on after one successful check; false if the
  /// check failed.
  Future<bool> enableBiometrics(BiometricPromptText text) async {
    final ok = await whileExternal(
      () => ref.read(biometricsProvider).authenticate(text),
    );
    if (!ok) return false;
    await _settings.setLockBiometric(true);
    state = state.copyWith(biometric: true);
    return true;
  }

  Future<void> disableBiometrics() async {
    await _settings.setLockBiometric(false);
    state = state.copyWith(biometric: false);
  }

  Future<void> setLockAfter(Duration after) async {
    await _settings.setLockAfter(after);
    state = state.copyWith(lockAfter: after);
  }

  /// After a forgotten PIN: erases every substance, dose and intake and the
  /// lock itself, keeping the language, theme and first day of the week.
  /// Permanent: with `secure_delete` on, SQLite zeroes the freed content,
  /// and the checkpoint drops WAL frames that still hold it.
  Future<void> eraseAll() async {
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      await db.delete(db.intakes).go();
      await db.delete(db.doses).go();
      await db.delete(db.substances).go();
      await _settings.clearLock();
    });
    await db.customSelect('PRAGMA wal_checkpoint(TRUNCATE)').get();
    await _reload(locked: false);
    await ref.read(recentsWindowProvider).setHidden(false);
  }
}
