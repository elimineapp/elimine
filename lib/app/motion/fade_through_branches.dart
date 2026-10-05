import 'package:flutter/material.dart';

import 'motion.dart';

/// Holds the tab navigators and fades through from one to the next: the
/// open tab fades out, then the selected one fades in while growing from a
/// slightly smaller scale. Every navigator stays mounted, so each tab keeps
/// its state.
class FadeThroughBranches extends StatefulWidget {
  const FadeThroughBranches({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<FadeThroughBranches> createState() => _FadeThroughBranchesState();
}

class _FadeThroughBranchesState extends State<FadeThroughBranches>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, value: 1)
    ..addStatusListener((status) {
      if (status.isCompleted) setState(() => _previous = null);
    });

  /// The tab fading out, while the transition runs.
  int? _previous;

  @override
  void didUpdateWidget(FadeThroughBranches oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    _previous = oldWidget.currentIndex;
    _controller
      ..duration = Motion.reducedOf(context) ? Motion.short : Motion.medium
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reducedOf(context);
    // Removed animations: a plain cross-fade without scaling.
    final fadeOut = ReverseAnimation(
      CurvedAnimation(
        parent: _controller,
        curve: reduced ? Curves.linear : const Interval(0, 0.35),
      ),
    );
    final fadeIn = CurvedAnimation(
      parent: _controller,
      curve: reduced
          ? Curves.linear
          : const Interval(0.35, 1, curve: Motion.standard),
    );
    final scaleIn = reduced
        ? kAlwaysCompleteAnimation
        : Tween(begin: 0.92, end: 1.0).animate(fadeIn);

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (i, child) in widget.children.indexed)
          _branch(
            child,
            active: i == widget.currentIndex,
            leaving: i == _previous,
            opacity: i == widget.currentIndex
                ? fadeIn
                : i == _previous
                ? fadeOut
                : kAlwaysCompleteAnimation,
            scale: i == widget.currentIndex
                ? scaleIn
                : kAlwaysCompleteAnimation,
          ),
      ],
    );
  }

  /// The same widget structure for every state, so a navigator is never
  /// remounted when its tab is selected or left.
  Widget _branch(
    Widget child, {
    required bool active,
    required bool leaving,
    required Animation<double> opacity,
    required Animation<double> scale,
  }) {
    final visible = active || leaving;
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: HeroMode(
          enabled: active,
          child: ExcludeFocus(
            excluding: !active,
            child: IgnorePointer(
              ignoring: !active,
              child: FadeTransition(
                opacity: opacity,
                child: ScaleTransition(
                  scale: scale,
                  child: RepaintBoundary(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
