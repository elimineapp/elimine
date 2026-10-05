import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'shared_axis.dart';
import 'predictive_back.dart';

/// The surface a screen grows out of and shrinks back into.
class TransitionOrigin {
  const TransitionOrigin({required this.key, this.radius = 0, this.color});

  /// Placed on the origin's surface widget.
  final GlobalKey key;

  /// The origin's corner radius, which straightens as it grows.
  final double radius;

  /// The origin's surface color; null blends from the screen's own.
  final Color? color;

  /// Where the origin is now, relative to [ancestor], or null when it is no
  /// longer laid out.
  Rect? rectIn(RenderObject? ancestor) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: ancestor) & box.size;
  }
}

/// A screen that grows out of [origin]: the origin's surface expands to
/// fill the screen while the screen fades in on it. Going back shrinks it
/// into wherever the origin is at that moment. Without an origin it comes
/// forward on the depth axis instead.
class ContainerTransformPage<T> extends Page<T> {
  const ContainerTransformPage({
    required this.child,
    this.origin,
    super.key,
    super.name,
  });

  final Widget child;
  final TransitionOrigin? origin;

  @override
  Route<T> createRoute(BuildContext context) => switch (origin) {
    final origin? => ContainerTransformRoute<T>(
      settings: this,
      origin: origin,
      builder: (context) => child,
    ),
    null => SharedAxisRoute<T>(settings: this, builder: (context) => child),
  };
}

class ContainerTransformRoute<T> extends PageRoute<T> {
  ContainerTransformRoute({
    required this.builder,
    required this.origin,
    super.settings,
  });

  final WidgetBuilder builder;
  final TransitionOrigin origin;

  /// Where the origin was last seen, kept for when it is gone.
  Rect? _lastOrigin;

  static final _fadeIn = CurveTween(curve: const Interval(0.3, 1));

  late final _progress = CurvedAnimation(
    parent: animation!,
    curve: Motion.transform,
  );

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Motion.long;

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  // A sheet replacing this screen shrinks out of it, over the page below,
  // which has to be drawn again.
  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    super.didChangeNext(nextRoute);
    if (nextRoute is PageRoute && !nextRoute.opaque) {
      overlayEntries.first.opaque = false;
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => PredictiveBack(
    route: this,
    child: _transitions(context, animation, secondaryAnimation, child),
  );

  Widget _transitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fades out when a sheet replaces it, as after saving a new substance.
    final leaving = FadeTransition(
      opacity: ReverseAnimation(secondaryAnimation),
      child: child,
    );
    if (Motion.reducedOf(context)) {
      return FadeTransition(opacity: animation, child: leaving);
    }
    final surface = Theme.of(context).colorScheme.surface;
    final navigatorBox = navigator?.context.findRenderObject();
    // The root navigator fills the screen.
    final full = Offset.zero & MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: _progress,
      child: leaving,
      // The same structure at every value, so the screen is never remounted.
      builder: (context, child) {
        final t = _progress.value;
        final from = _lastOrigin = origin.rectIn(navigatorBox) ?? _lastOrigin;
        return Stack(
          children: [
            Positioned.fromRect(
              rect: Rect.lerp(from ?? full, full, t)!,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  lerpDouble(origin.radius, 0, t)!,
                ),
                child: ColoredBox(
                  color: Color.lerp(origin.color ?? surface, surface, t)!,
                  // The screen keeps its full layout and scales to the
                  // surface's width, anchored at its top edge.
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    child: SizedBox.fromSize(
                      size: full.size,
                      child: FadeTransition(
                        opacity: _fadeIn.animate(animation),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
