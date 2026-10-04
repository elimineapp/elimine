import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/l10n/format.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dose_chips.dart';
import '../../widgets/intake_tile.dart';
import '../../widgets/intake_time_field.dart';
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
    final last = intakes.firstOrNull;
    final DoseChoice selected =
        _choice ??
        (amount: last != null ? last.amount : doses.firstOrNull?.amount);

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
                IntakeTimeField(
                  value: _at,
                  clock: widget.clock,
                  onChanged: (at) => setState(() => _at = at),
                ),
                const SizedBox(height: 24),
                Text(l.doseTitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                DoseChips(
                  amounts: [for (final d in doses) d.amount, ?last?.amount],
                  selected: selected.amount,
                  unit: substance.unit,
                  onChanged: (amount) =>
                      setState(() => _choice = (amount: amount)),
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
            itemBuilder: (context, i) => IntakeTile(
              intake: intakes[i],
              unit: substance.unit,
              clock: widget.clock,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}
