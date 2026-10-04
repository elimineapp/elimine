import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/l10n/format.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/intake_tile.dart';
import '../../widgets/substance_badge.dart';
import 'substance_chart.dart';

/// A chosen dose; a null amount means none is selected: the intake has no
/// dose.
typedef DoseChoice = ({double? amount});

/// Logging block plus this substance's history. The usual flow is two taps:
/// the tile on the home screen, then "Log" with the last dose preselected.
class SubstanceScreen extends ConsumerStatefulWidget {
  const SubstanceScreen({
    super.key,
    required this.substanceId,
    this.clock = DateTime.now,
  });

  final String substanceId;
  final DateTime Function() clock;

  @override
  ConsumerState<SubstanceScreen> createState() => _SubstanceScreenState();
}

class _SubstanceScreenState extends ConsumerState<SubstanceScreen> {
  /// NULL means "now", resolved when logging.
  DateTime? _at;

  /// NULL means "the default": the last intake's dose (or none if it had
  /// none), else the first frequent dose, else none.
  DoseChoice? _choice;

  DateTime _now() => widget.clock();

  DateTime _clamp(DateTime at) {
    final now = _now();
    return at.isAfter(now) ? now : at;
  }

  /// Moves to [day] keeping the currently chosen time of day.
  void _selectDay(DateTime day) {
    final t = _at ?? _now();
    setState(
      () => _at = _clamp(
        DateTime(day.year, day.month, day.day, t.hour, t.minute),
      ),
    );
  }

  /// Android has no combined picker, so the date comes first, then the time.
  /// Cancelling either step keeps the previous choice.
  Future<void> _pickDateTime() async {
    final now = _now();
    final base = _at ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;
    setState(
      () => _at = _clamp(
        DateTime(date.year, date.month, date.day, time.hour, time.minute),
      ),
    );
  }

  Future<void> _pickCustomAmount(Substance substance) async {
    final l = AppLocalizations.of(context);
    final value = await showDialog<double>(
      context: context,
      builder: (context) =>
          _CustomDoseDialog(title: l.customDoseTitle, unit: substance.unit),
    );
    if (value != null) setState(() => _choice = (amount: value));
  }

  Future<void> _log(Substance substance, double? amount) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(intakeServiceProvider);

    final id = await service.log(
      substanceId: substance.id,
      amount: amount,
      takenAt: _at,
    );
    HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() {
        _at = null;
        _choice = null;
      });
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            amount == null
                ? l.intakeLoggedNoDose
                : l.intakeLogged(l.dose(amount, substance.unit)),
          ),
          action: SnackBarAction(
            label: l.undo,
            onPressed: () => service.delete(id),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final substance = ref.watch(substanceProvider(widget.substanceId)).value;
    final doses =
        ref.watch(dosesProvider(widget.substanceId)).value ?? const [];
    final intakes =
        ref.watch(substanceIntakesProvider(widget.substanceId)).value ??
        const [];

    if (substance == null) {
      return Scaffold(appBar: AppBar());
    }

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = _now();
    final last = intakes.firstOrNull;
    final DoseChoice selected =
        _choice ??
        (amount: last != null ? last.amount : doses.firstOrNull?.amount);
    final amounts = <double>{
      for (final d in doses) d.amount,
      ?last?.amount,
      ?selected.amount,
    }.toList()..sort();

    final at = _at;
    final daysAgo = at == null ? null : calendarDaysBetween(at, now);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 12,
          children: [
            SubstanceBadge(
              color: substance.color,
              icon: substance.icon,
              size: 32,
            ),
            Flexible(
              child: Text(substance.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/substance/${substance.id}/edit'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList.list(
              children: [
                Card.filled(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    key: const Key('timeRow'),
                    leading: const Icon(Icons.schedule),
                    title: Text(
                      at == null
                          ? l.timeNowAt(DateFormat.Hm(l.localeName).format(now))
                          : l.dayAndTime(at, now),
                    ),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: _pickDateTime,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l.timeNow),
                      selected: at == null,
                      onSelected: (_) => setState(() => _at = null),
                    ),
                    ChoiceChip(
                      label: Text(l.dayYesterday),
                      selected: daysAgo == 1,
                      onSelected: (_) =>
                          _selectDay(now.subtract(const Duration(days: 1))),
                    ),
                    ChoiceChip(
                      label: Text(l.dayBeforeYesterday),
                      selected: daysAgo == 2,
                      onSelected: (_) =>
                          _selectDay(now.subtract(const Duration(days: 2))),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(l.doseTitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  key: const Key('doses'),
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final amount in amounts)
                      ChoiceChip(
                        label: Text(l.dose(amount, substance.unit)),
                        selected: amount == selected.amount,
                        // Tapping the selected dose again clears it.
                        onSelected: (on) => setState(
                          () => _choice = (amount: on ? amount : null),
                        ),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: Text(l.customDose),
                      onPressed: () => _pickCustomAmount(substance),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('logButton'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    textStyle: theme.textTheme.titleMedium,
                  ),
                  onPressed: () => _log(substance, selected.amount),
                  child: Text(l.logButton),
                ),
                const SizedBox(height: 32),
                SubstanceChart(substance: substance, clock: widget.clock),
                const SizedBox(height: 24),
                Text(l.historyTitle, style: theme.textTheme.titleSmall),
                if (intakes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l.emptyIntakes,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SliverList.builder(
            itemCount: intakes.length,
            itemBuilder: (context, i) =>
                IntakeTile(intake: intakes[i], unit: substance.unit),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
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
