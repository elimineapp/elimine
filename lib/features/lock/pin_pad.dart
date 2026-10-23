import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/motion/motion.dart';
import '../../l10n/app_localizations.dart';

/// The digits entered so far.
class PinController extends ValueNotifier<String> {
  PinController() : super('');

  void clear() => value = '';
}

/// Dots for the entered digits above a numeric keypad. The app's own keypad
/// rather than the system keyboard, so digits never reach a keyboard app.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.controller,
    this.length,
    this.maxLength = 8,
    this.onComplete,
    this.onBiometric,
    this.enabled = true,
    this.errors = 0,
  });

  final PinController controller;

  /// The stored PIN's length: as many dots, and [onComplete] once it is
  /// reached. Null while choosing a PIN.
  final int? length;
  final int maxLength;
  final ValueChanged<String>? onComplete;

  /// Shows the biometric key bottom left.
  final VoidCallback? onBiometric;
  final bool enabled;

  /// Raised by the parent after each wrong PIN: the dots shake.
  final int errors;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  int get _limit => widget.length ?? widget.maxLength;

  @override
  void didUpdateWidget(PinPad old) {
    super.didUpdateWidget(old);
    if (widget.errors > old.errors) {
      HapticFeedback.vibrate();
      if (!Motion.reducedOf(context)) _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _digit(int d) {
    final pin = widget.controller.value;
    if (pin.length >= _limit) return;
    final next = '$pin$d';
    widget.controller.value = next;
    if (next.length == widget.length) widget.onComplete?.call(next);
  }

  void _delete() {
    final pin = widget.controller.value;
    if (pin.isNotEmpty) {
      widget.controller.value = pin.substring(0, pin.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder(
          valueListenable: widget.controller,
          builder: (context, pin, _) {
            // Placeholders up to the stored length, or the shortest PIN.
            final shown = max(widget.length ?? 4, pin.length);
            return Semantics(
              label: l.pinDigitsEntered(pin.length),
              liveRegion: true,
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _shake,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(sin(_shake.value * pi * 6) * 12, 0),
                    child: child,
                  ),
                  child: SizedBox(
                    height: 16,
                    child: Row(
                      key: const Key('pin-dots'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < shown; i++)
                          Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < pin.length ? colors.primary : null,
                              border: Border.all(
                                color: colors.outline,
                                width: i < pin.length ? 0 : 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        for (final row in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (final d in row) _digitKey(d)],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.onBiometric == null
                ? const SizedBox(width: _Key.size + 2 * _Key.padding)
                : _Key(
                    key: const Key('pin-biometric'),
                    label: l.useBiometrics,
                    onPressed: widget.onBiometric,
                    child: const Icon(Icons.fingerprint, size: 32),
                  ),
            _digitKey(0),
            _Key(
              key: const Key('pin-delete'),
              label: l.deleteDigit,
              onPressed: widget.enabled ? _delete : null,
              child: const Icon(Icons.backspace_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _digitKey(int d) => _Key(
    key: Key('pin-$d'),
    label: '$d',
    onPressed: widget.enabled ? () => _digit(d) : null,
    child: Text('$d'),
  );
}

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.label,
    required this.onPressed,
    required this.child,
  });

  static const size = 72.0;
  static const padding = 8.0;

  final String label;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(padding),
    child: Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: TextButton(
          onPressed: onPressed,
          // The size only: a color in the text style would keep disabled
          // digits as bright as enabled ones.
          style: TextButton.styleFrom(
            shape: const CircleBorder(),
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            textStyle: Theme.of(context).textTheme.headlineMedium,
          ),
          child: child,
        ),
      ),
    ),
  );
}
