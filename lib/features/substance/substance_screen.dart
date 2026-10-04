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

/// The substance screen, a sheet over Home. Collapsed, it holds the logging
/// block for the usual two taps: the tile, then "Log" with the last dose
/// preselected. Pulled up, it fills the screen with the chart and history.
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
  /// The pinned header: drag handle, then the substance row.
  static const _headerHeight = 88.0;

  /// How much of the chart shows below the collapsed sheet's logging block,
  /// hinting that there is more above.
  static const _chartPeek = 56.0;

  /// How far the expand hint lifts the collapsed sheet.
  static const _hintLift = 28.0;

  /// NULL means "now", resolved when logging.
  DateTime? _at;

  /// NULL means "the default": the last intake's dose (or none if it had
  /// none), else the first frequent dose, else none.
  DoseChoice? _choice;

  final _sheet = DraggableScrollableController();
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  final _logBlock = GlobalKey();
  ScrollController? _scroll;

  /// Height of the collapsed sheet in pixels, measured from the logging
  /// block; null until it has been laid out.
  double? _collapsedHeight;
  double _collapsed = 0.6;
  List<double> _snapSizes = const [0.6];
  bool _expanded = false;
  bool _hintDone = false;

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_onSizeChanged);
  }

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  void _onSizeChanged() {
    final expanded = _sheet.size >= 0.99;
    if (expanded == _expanded) return;
    setState(() => _expanded = expanded);
    if (expanded && ref.read(sheetExpandedProvider).value != true) {
      ref.read(settingsServiceProvider).setSheetExpanded();
    }
  }

  /// Sizes the collapsed sheet to end just below the "Chart and history"
  /// row, plus a strip of the chart. Re-measured while collapsed, because
  /// the dose chips may wrap onto another line.
  void _measure() {
    if (!mounted || _expanded) return;
    final box = _logBlock.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final height = _headerHeight + box.size.height + _chartPeek;
    if (height != _collapsedHeight) {
      setState(() => _collapsedHeight = height);
      return;
    }
    _maybeHint();
  }

  /// Until a substance screen has been expanded once, lifts the collapsed
  /// sheet a little and lets it settle, once the sheet has finished opening.
  void _maybeHint() {
    if (_hintDone) return;
    final seen = ref.read(sheetExpandedProvider).value;
    if (seen == null) return;
    _hintDone = true;
    if (seen) return;

    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _hint();
      return;
    }
    void onStatus(AnimationStatus status) {
      if (!status.isCompleted) return;
      animation.removeStatusListener(onStatus);
      _hint();
    }

    animation.addStatusListener(onStatus);
  }

  Future<void> _hint() async {
    if (!mounted || !_sheet.isAttached || _expanded) return;
    final rest = _sheet.size;
    await _sheet.animateTo(
      rest + _sheet.pixelsToSize(_hintLift),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
    if (!mounted || !_sheet.isAttached) return;
    await _sheet.animateTo(
      rest,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _expand() => _sheet.animateTo(
    1,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
  );

  void _collapse() {
    final scroll = _scroll;
    if (scroll != null && scroll.hasClients) scroll.jumpTo(0);
    _sheet.animateTo(
      _collapsed,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Collapsed, logging closes the sheet and reports on Home; expanded, the
  /// user stays and sees the new entry on top of History.
  Future<void> _log(Substance substance, double? amount) async {
    final l = AppLocalizations.of(context);
    final stay = _expanded;
    // The State's context sits above the sheet's own messenger, so this one
    // is Home's.
    final messenger = stay
        ? _messenger.currentState!
        : ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
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
    if (!stay) navigator.maybePop();
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
    // Watched so the hint can decide as soon as the flag is known.
    ref.watch(sheetExpandedProvider);
    final theme = Theme.of(context);

    if (substance != null && !_expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight;
        final collapsed = ((_collapsedHeight ?? available * 0.6) / available)
            .clamp(0.3, 0.9);
        if (collapsed != _collapsed) {
          _collapsed = collapsed;
          _snapSizes = [collapsed];
          // The sheet keeps its size once it has moved, so a new collapsed
          // size has to be applied to it.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _sheet.isAttached && !_expanded) {
              _sheet.jumpTo(collapsed);
            }
          });
        }
        return DraggableScrollableSheet(
          controller: _sheet,
          expand: false,
          snap: true,
          // Dragging below the collapsed size closes the sheet.
          minChildSize: 0,
          initialChildSize: collapsed,
          snapSizes: _snapSizes,
          builder: (context, scroll) {
            _scroll = scroll;
            return Material(
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(_expanded ? 0 : 28),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              // Its own messenger, so snackbars show above the sheet rather
              // than behind its barrier.
              child: ScaffoldMessenger(
                key: _messenger,
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: substance == null
                      ? const SizedBox.shrink()
                      : _content(substance, doses, intakes, scroll),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _content(
    Substance substance,
    List<Dose> doses,
    List<Intake> intakes,
    ScrollController scroll,
  ) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final last = intakes.firstOrNull;
    final DoseChoice selected =
        _choice ??
        (amount: last != null ? last.amount : doses.firstOrNull?.amount);

    return CustomScrollView(
      controller: scroll,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _HeaderDelegate(
            height: _headerHeight,
            child: _Header(
              substance: substance,
              lastLabel: l.lastIntake(last, substance.unit, widget.clock()),
              expanded: _expanded,
              onCollapse: _collapse,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              key: _logBlock,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                // Kept in the layout when expanded, so the content below
                // does not jump as the sheet reaches the top.
                Visibility(
                  visible: !_expanded,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: _ChartAndHistoryRow(
                    count: intakes.length,
                    onTap: _expand,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.list(
            children: [
              SubstanceChart(substance: substance, clock: widget.clock),
              const SizedBox(height: 24),
              Text(l.historyTitle, style: theme.textTheme.titleSmall),
              if (intakes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l.emptyIntakes,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
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
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
          ),
        ),
      ],
    );
  }
}

/// The handle and the substance row. Collapsed, it shows the handle and the
/// last intake; expanded, a "Collapse" action takes the handle's role.
class _Header extends StatelessWidget {
  const _Header({
    required this.substance,
    required this.lastLabel,
    required this.expanded,
    required this.onCollapse,
  });

  final Substance substance;
  final String lastLabel;
  final bool expanded;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          SizedBox(
            height: 16,
            child: Center(
              child: AnimatedOpacity(
                opacity: expanded ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 72,
            child: Row(
              children: [
                if (expanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      key: const Key('collapseSheet'),
                      tooltip: l.collapse,
                      icon: const Icon(Icons.expand_more),
                      onPressed: onCollapse,
                    ),
                  )
                else
                  const SizedBox(width: 16),
                SubstanceBadge(
                  color: substance.color,
                  icon: substance.icon,
                  filled: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        substance.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        lastLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('editSubstance'),
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () =>
                      context.push('/substance/${substance.id}/edit'),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(_HeaderDelegate oldDelegate) => true;
}

/// "Chart and history" with the number of intakes: expands the sheet.
class _ChartAndHistoryRow extends StatelessWidget {
  const _ChartAndHistoryRow({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return TextButton(
      key: const Key('chartAndHistory'),
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: theme.colorScheme.onSurfaceVariant,
      ),
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          const Icon(Icons.keyboard_arrow_up),
          Text(l.chartAndHistory),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              child: Text('$count', style: theme.textTheme.labelSmall),
            ),
          ),
        ],
      ),
    );
  }
}
