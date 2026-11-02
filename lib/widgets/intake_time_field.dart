import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/l10n/format.dart';
import '../l10n/app_localizations.dart';

/// The time of an intake: a row opening the date and time pickers, then the
/// "Now", "Yesterday" and "Day before" chips. A null [value] means "now",
/// resolved by whoever stores it. Future picks are clamped to now.
class IntakeTimeField extends StatelessWidget {
  const IntakeTimeField({
    super.key,
    required this.value,
    required this.clock,
    required this.onChanged,
  });

  final DateTime? value;
  final DateTime Function() clock;
  final ValueChanged<DateTime?> onChanged;

  DateTime _clamp(DateTime at) {
    final now = clock();
    return at.isAfter(now) ? now : at;
  }

  /// Moves [days] calendar days back from today, keeping the currently
  /// chosen time of day. Counted by date, not by 24-hour steps, which miss a
  /// day after a short one, such as the switch to summer time.
  void _selectDaysAgo(int days) {
    final now = clock();
    final t = value ?? now;
    onChanged(
      _clamp(DateTime(now.year, now.month, now.day - days, t.hour, t.minute)),
    );
  }

  /// Android has no combined picker, so the date comes first, then the time.
  /// Cancelling either step keeps the previous choice.
  Future<void> _pickDateTime(BuildContext context) async {
    final now = clock();
    final base = value ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;
    onChanged(
      _clamp(DateTime(date.year, date.month, date.day, time.hour, time.minute)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final now = clock();
    final at = value;
    final daysAgo = at == null ? null : calendarDaysBetween(at, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
            onTap: () => _pickDateTime(context),
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
              onSelected: (_) => onChanged(null),
            ),
            ChoiceChip(
              label: Text(l.dayYesterday),
              selected: daysAgo == 1,
              onSelected: (_) => _selectDaysAgo(1),
            ),
            ChoiceChip(
              label: Text(l.dayBeforeYesterday),
              selected: daysAgo == 2,
              onSelected: (_) => _selectDaysAgo(2),
            ),
          ],
        ),
      ],
    );
  }
}
