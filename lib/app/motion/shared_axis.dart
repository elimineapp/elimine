import 'package:flutter/material.dart';

import 'motion.dart';
import 'predictive_back.dart';

/// A page that comes forward on the depth axis: it fades in while growing
/// from a smaller scale, as the page below grows past the viewer and fades
/// away. Going back reverses it.
class SharedAxisPage<T> extends Page<T> {
  const SharedAxisPage({required this.child, super.key, super.name});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) =>
      SharedAxisRoute<T>(settings: this, builder: (context) => child);
}

class SharedAxisRoute<T> extends PageRoute<T> {
  SharedAxisRoute({required this.builder, super.settings});

  final WidgetBuilder builder;

  static final _fadeIn = CurveTween(
    curve: const Interval(0.3, 1, curve: Motion.standard),
  );
  static final _scaleIn = Tween(
    begin: 0.8,
    end: 1.0,
  ).chain(CurveTween(curve: Motion.standard));
  static final _fadeOut = Tween(
    begin: 1.0,
    end: 0.0,
  ).chain(CurveTween(curve: const Interval(0, 0.3, curve: Motion.standard)));
  static final _scaleOut = Tween(
    begin: 1.0,
    end: 1.1,
  ).chain(CurveTween(curve: Motion.standard));

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Motion.medium;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      (context, animation, secondaryAnimation, allowSnapshotting, child) {
        if (Motion.reducedOf(context)) return child;
        return FadeTransition(
          opacity: _fadeOut.animate(secondaryAnimation),
          child: ScaleTransition(
            scale: _scaleOut.animate(secondaryAnimation),
            child: child,
          ),
        );
      };

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
    if (Motion.reducedOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    return FadeTransition(
      opacity: _fadeIn.animate(animation),
      child: ScaleTransition(scale: _scaleIn.animate(animation), child: child),
    );
  }
}
