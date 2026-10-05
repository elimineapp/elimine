import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'motion/container_transform.dart';
import 'motion/motion.dart';
import 'motion/predictive_back.dart';

/// A page shown as a modal bottom sheet over the page below it. The child
/// draws its own surface and handle, usually through a
/// [DraggableScrollableSheet], which also closes the sheet when dragged to
/// its minimum size.
class SheetPage<T> extends Page<T> {
  const SheetPage({
    required this.child,
    this.entrance = SheetEntrance.slide,
    super.key,
    super.name,
  });

  final Widget child;
  final SheetEntrance entrance;

  @override
  Route<T> createRoute(BuildContext context) => SheetRoute<T>(
    settings: this,
    builder: (context) => child,
    entrance: entrance,
    barrierLabel: MaterialLocalizations.of(context).scrimLabel,
  );
}

/// How a sheet comes in.
enum SheetEntrance {
  /// Rising from the bottom.
  slide,

  /// Shrinking from the full screen down to its size, in place of the
  /// screen it replaces.
  fromFullScreen,
}

/// A modal bottom sheet that is a [PageRoute], so the substance icon can
/// fly into and out of it as a [Hero] and screens opened above it can
/// animate it along with them.
class SheetRoute<T> extends PageRoute<T> {
  SheetRoute({
    required this.builder,
    required this.barrierLabel,
    this._entrance = SheetEntrance.slide,
    super.settings,
  });

  final WidgetBuilder builder;

  /// How it comes in. Once in, it leaves by sliding down whatever the
  /// entrance was.
  SheetEntrance _entrance;

  void _onStatus(AnimationStatus status) {
    if (status.isCompleted) _entrance = SheetEntrance.slide;
  }

  @override
  final String? barrierLabel;

  /// How long the entrance waits for [reveal] before starting anyway.
  static const _revealWait = Duration(milliseconds: 150);

  bool _revealed = false;
  Timer? _revealTimeout;

  /// Starts the entrance held back by [didPush]. The content calls it once
  /// it knows its size, so the sheet rises at its final height.
  static void revealOf(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route is SheetRoute) route.reveal();
  }

  void reveal() {
    if (_revealed) return;
    _revealed = true;
    _revealTimeout?.cancel();
    final controller = this.controller;
    // Stopped, not dismissed: the status stays "forward" while held.
    if (isActive &&
        controller != null &&
        controller.value == 0 &&
        !controller.isAnimating) {
      controller.forward();
    }
  }

  @override
  TickerFuture didPush() {
    // The controller, not the route's animation: Hero setup briefly
    // reports that one as completed.
    controller!.addStatusListener(_onStatus);
    final pushed = super.didPush();
    if (!_revealed) {
      // Held at the start until the content has measured itself.
      controller!.stop(canceled: false);
      _revealTimeout = Timer(_revealWait, reveal);
    }
    return pushed;
  }

  @override
  void dispose() {
    _revealTimeout?.cancel();
    controller?.removeStatusListener(_onStatus);
    _progress.dispose();
    _shrink.dispose();
    super.dispose();
  }

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => Colors.black54;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Motion.medium;

  @override
  Duration get reverseTransitionDuration => Motion.short;

  // Only a screen growing out of it moves it: its content fades as that
  // screen's surface grows. Other routes above leave it still.
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is ContainerTransformRoute;

  static final _fadeOut = Tween(
    begin: 1.0,
    end: 0.0,
  ).chain(CurveTween(curve: const Interval(0, 0.3)));

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final sheet = NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent == notification.minExtent &&
            notification.shouldCloseOnMinExtent &&
            isCurrent) {
          navigator?.pop();
        }
        return false;
      },
      child: Builder(builder: builder),
    );
    // Full-screen, with the sheet at the bottom: the page keeps the
    // screen's origin, so a Hero flies to where the sheet ends up.
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: MaterialLocalizations.of(context).dialogLabel,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: _HeightReporter(
            onHeight: (height) => _sheetHeight = height,
            child: sheet,
          ),
        ),
      ),
    );
  }

  /// The sheet's height at the last layout, which the entrance slides it by.
  double? _sheetHeight;

  late final _progress = CurvedAnimation(
    parent: animation!,
    curve: Motion.emphasized,
    reverseCurve: Motion.emphasizedExit,
  );

  late final _shrink = CurvedAnimation(
    parent: animation!,
    curve: Motion.transform,
  );

  static const _fadeIn = Interval(0.3, 1);
  static const _takeOver = Interval(0, 0.2);

  /// Matches the collapsed sheet's top corners.
  static const _cornerRadius = 28.0;

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
    child = FadeTransition(
      opacity: _fadeOut.animate(secondaryAnimation),
      child: child,
    );
    if (Motion.reducedOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      // The same structure in both entrances, so the sheet is never
      // remounted when it switches to sliding.
      builder: (context, child) {
        final screen = MediaQuery.sizeOf(context).height;
        // Before its first layout the sheet's height is unknown: below the
        // screen is out of sight either way.
        final height = _sheetHeight ?? screen;
        final shrinking = _entrance == SheetEntrance.fromFullScreen;
        final t = shrinking ? _shrink.value : _progress.value;
        return Stack(
          children: [
            // The surface shrinking from the full screen to the sheet. It
            // takes over from the replaced screen's background as that
            // screen fades.
            Positioned(
              top: shrinking ? (screen - height) * t : screen,
              left: 0,
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: shrinking ? _takeOver.transform(animation.value) : 0,
                child: ClipRRect(
                  key: const Key('sheetEntranceSurface'),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_cornerRadius * t),
                  ),
                  child: ColoredBox(
                    color: Color.lerp(
                      colors.surface,
                      colors.surfaceContainerLow,
                      t,
                    )!,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, shrinking ? 0 : (1 - t) * height),
                child: Opacity(
                  opacity: shrinking ? _fadeIn.transform(animation.value) : 1,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Reports its child's height after each layout.
class _HeightReporter extends SingleChildRenderObjectWidget {
  const _HeightReporter({required this.onHeight, super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeightReporter(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeightReporter renderObject,
  ) => renderObject.onHeight = onHeight;
}

class _RenderHeightReporter extends RenderProxyBox {
  _RenderHeightReporter(this.onHeight);

  ValueChanged<double> onHeight;

  @override
  void performLayout() {
    super.performLayout();
    onHeight(size.height);
  }
}
