import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'pin_entry.dart';
import 'pin_pad.dart';

/// Lets the user choose a new PIN of 4 to 8 digits, entered twice; returns
/// it, or null when the user goes back. [warn] adds the warning about a
/// forgotten PIN, for turning the lock on.
Future<String?> choosePin(BuildContext context, {required bool warn}) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PinSetupScreen(warn: warn),
      ),
    );

/// Asks for the current PIN, or a biometric check; true once it is right.
Future<bool> verifyPin(BuildContext context) async {
  final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: PinEntry(
                title: AppLocalizations.of(context).enterCurrentPin,
                onRight: () => Navigator.pop(context, true),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, required this.warn});

  final bool warn;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  static const minLength = 4;

  final _pin = PinController();

  /// The PIN entered in the first step, while it is being confirmed.
  String? _first;
  bool _mismatch = false;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _next() {
    final pin = _pin.value;
    final first = _first;
    if (first == null) {
      setState(() {
        _first = pin;
        _mismatch = false;
      });
    } else if (pin == first) {
      Navigator.pop(context, pin);
      return;
    } else {
      setState(() {
        _first = null;
        _mismatch = true;
      });
    }
    _pin.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final choosing = _first == null;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                choosing ? l.choosePin : l.confirmPin,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _mismatch ? l.pinsDoNotMatch : l.choosePinHint,
                key: const Key('pin-setup-hint'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _mismatch
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // On both steps, so the keypad stays where the thumb is.
              if (widget.warn) ...[
                const SizedBox(height: 16),
                Card(
                  key: const Key('pin-setup-warning'),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined),
                        const SizedBox(width: 16),
                        Expanded(child: Text(l.pinSetupWarning)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              PinPad(controller: _pin),
              const SizedBox(height: 24),
              ValueListenableBuilder(
                valueListenable: _pin,
                builder: (context, pin, _) => SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('pin-next'),
                    onPressed: pin.length >= minLength ? _next : null,
                    child: Text(choosing ? l.pinNext : l.pinDone),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
