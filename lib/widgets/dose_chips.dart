import 'package:flutter/material.dart';

import '../core/l10n/format.dart';
import '../l10n/app_localizations.dart';

/// A chip per amount, then "Custom", which asks for a number. At most one
/// amount is selected; tapping it again clears it, and a null [selected]
/// means no dose.
class DoseChips extends StatelessWidget {
  const DoseChips({
    super.key,
    required this.amounts,
    required this.selected,
    required this.unit,
    required this.onChanged,
  });

  /// The substance's doses plus any extra amount to offer; [selected] is
  /// always shown.
  final Iterable<double> amounts;
  final double? selected;
  final String unit;
  final ValueChanged<double?> onChanged;

  Future<void> _pickCustomAmount(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final value = await showDialog<double>(
      context: context,
      builder: (context) =>
          _CustomDoseDialog(title: l.customDoseTitle, unit: unit),
    );
    if (value != null) onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final chips = <double>{...amounts, ?selected}.toList()..sort();

    return Wrap(
      key: const Key('doses'),
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final amount in chips)
          ChoiceChip(
            label: Text(l.dose(amount, unit)),
            selected: amount == selected,
            // Tapping the selected dose again clears it.
            onSelected: (on) => onChanged(on ? amount : null),
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l.customDose),
          onPressed: () => _pickCustomAmount(context),
        ),
      ],
    );
  }
}

class _CustomDoseDialog extends StatefulWidget {
  const _CustomDoseDialog({required this.title, required this.unit});

  final String title;
  final String unit;

  @override
  State<_CustomDoseDialog> createState() => _CustomDoseDialogState();
}

class _CustomDoseDialogState extends State<_CustomDoseDialog> {
  final _controller = TextEditingController();

  double? get _value => parseAmount(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final value = _value;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          suffixText: widget.unit.isEmpty ? null : widget.unit,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (value != null) Navigator.pop(context, value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: value == null ? null : () => Navigator.pop(context, value),
          child: Text(l.ok),
        ),
      ],
    );
  }
}
