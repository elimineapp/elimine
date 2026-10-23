import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import 'app_lock.dart';
import 'biometrics.dart';
import 'pin_pad.dart';

BiometricPromptText biometricPromptText(AppLocalizations l) => (
  title: l.biometricPromptTitle,
  reason: l.biometricPromptReason,
  cancel: l.biometricPromptCancel,
);

/// Asks for the stored PIN, or a biometric check when biometric unlock is
/// on, with wrong-PIN throttling. Used by the lock screen ([unlock]) and
/// wherever the current PIN must be confirmed.
class PinEntry extends ConsumerStatefulWidget {
  const PinEntry({
    super.key,
    required this.title,
    required this.onRight,
    this.unlock = false,
    this.header,
    this.footer,
  });

  final String title;
  final VoidCallback onRight;

  /// Unlocks the app on success, and shows the biometric prompt at once.
  final bool unlock;
  final Widget? header;
  final Widget? footer;

  @override
  ConsumerState<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends ConsumerState<PinEntry> {
  final _pin = PinController();
  int _errors = 0;
  bool _wrong = false;
  bool _busy = false;
  bool _biometricsAvailable = false;
  Timer? _ticker;

  AppLock get _lock => ref.read(appLockProvider.notifier);

  @override
  void initState() {
    super.initState();
    if (ref.read(appLockProvider).biometric) _initBiometrics();
  }

  /// Biometrics removed from the device leave only the keypad.
  Future<void> _initBiometrics() async {
    final available = await ref.read(biometricsProvider).isAvailable();
    if (!mounted || !available) return;
    setState(() => _biometricsAvailable = true);
    if (widget.unlock) _biometrics();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _check(String pin) async {
    setState(() => _busy = true);
    final result = widget.unlock
        ? await _lock.unlockWithPin(pin)
        : await _lock.checkPin(pin);
    if (!mounted) return;
    _pin.clear();
    setState(() {
      _busy = false;
      _wrong = result == PinCheck.wrong;
      if (_wrong) _errors++;
    });
    if (result == PinCheck.right) widget.onRight();
  }

  Future<void> _biometrics() async {
    final text = biometricPromptText(AppLocalizations.of(context));
    final ok = widget.unlock
        ? await _lock.unlockWithBiometrics(text)
        : await _lock.checkBiometrics(text);
    if (ok && mounted) widget.onRight();
  }

  /// While input is refused, the time left, renewed every second.
  Duration? _blockedFor(DateTime? until) {
    final left = until?.difference(ref.read(clockProvider)());
    if (left == null || left <= Duration.zero) {
      _ticker?.cancel();
      _ticker = null;
      return null;
    }
    _ticker ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
    return left;
  }

  static String _format(Duration d) {
    final seconds = (d.inMilliseconds / 1000).ceil();
    String two(int n) => n.toString().padLeft(2, '0');
    final h = seconds ~/ 3600, m = seconds ~/ 60 % 60, s = seconds % 60;
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(appLockProvider);
    final blocked = _blockedFor(state.blockedUntil);
    final message = blocked != null
        ? l.pinBlocked(_format(blocked))
        : _wrong
        ? l.wrongPin
        : '';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ?widget.header,
        Text(widget.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 24),
        PinPad(
          controller: _pin,
          length: state.pinLength,
          enabled: blocked == null && !_busy,
          errors: _errors,
          onComplete: _check,
          onBiometric: state.biometric && _biometricsAvailable
              ? _biometrics
              : null,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: Text(
            message,
            key: const Key('pin-message'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        ?widget.footer,
      ],
    );
  }
}
