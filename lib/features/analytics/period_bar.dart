import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// "‹ October 2026 ›": the displayed period with arrows to step through
/// periods. A null callback disables its arrow; tapping the label returns to
/// the current period.
class PeriodBar extends StatelessWidget {
  const PeriodBar({
    super.key,
    required this.label,
    this.onPrevious,
    this.onNext,
    this.onToday,
    this.arrows = true,
  });

  final String label;

  /// False for a period that cannot step, such as "All years".
  final bool arrows;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        if (arrows)
          IconButton(
            key: const Key('previousPeriod'),
            tooltip: l.previousPeriod,
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
        Expanded(
          child: TextButton(
            key: const Key('periodLabel'),
            onPressed: onToday,
            child: Text(label, textAlign: TextAlign.center),
          ),
        ),
        if (arrows)
          IconButton(
            key: const Key('nextPeriod'),
            tooltip: l.nextPeriod,
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
      ],
    );
  }
}

/// One page per period, the current one first and older ones to the left,
/// so the chart follows the finger and the next period slides in. Taps pass
/// through to the pages.
class PeriodPages extends StatelessWidget {
  const PeriodPages({
    super.key,
    required this.controller,
    required this.count,
    required this.height,
    required this.onPageChanged,
    required this.itemBuilder,
  });

  final PageController controller;
  final int count;
  final double height;

  /// Called with the number of periods back from the current one.
  final ValueChanged<int> onPageChanged;

  /// Builds the page [back] periods before the current one.
  final Widget Function(BuildContext context, int back) itemBuilder;

  /// Room above each page: the top axis label is centred on the top grid
  /// line and would otherwise be clipped by the page.
  static const _headroom = 10.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height + _headroom,
    child: PageView.builder(
      controller: controller,
      reverse: true,
      itemCount: count,
      onPageChanged: onPageChanged,
      itemBuilder: (context, back) => Padding(
        padding: const EdgeInsets.only(top: _headroom),
        child: itemBuilder(context, back),
      ),
    ),
  );
}

/// Duration and curve for stepping by the arrows.
const periodPageDuration = Duration(milliseconds: 280);
const periodPageCurve = Curves.easeOutCubic;
