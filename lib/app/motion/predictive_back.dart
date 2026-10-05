import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Lets the system back gesture drive [route]'s transition: while the
/// finger moves, the route plays its closing transition backward in step;
/// a committed gesture pops it and a cancelled one restores it.
///
/// Flutter only does this for routes built with Material's predictive back
/// transition, so custom routes wrap their transitions in this.
class PredictiveBack extends StatefulWidget {
  const PredictiveBack({super.key, required this.route, required this.child});

  final PageRoute<dynamic> route;
  final Widget child;

  @override
  State<PredictiveBack> createState() => _PredictiveBackState();
}

class _PredictiveBackState extends State<PredictiveBack>
    with WidgetsBindingObserver {
  /// Whether this route took the gesture in progress.
  bool _tracking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final route = widget.route;
    if (backEvent.isButtonEvent ||
        !route.isCurrent ||
        !route.popGestureEnabled) {
      return false;
    }
    _tracking = true;
    route.handleStartBackGesture(progress: 1 - backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_tracking) return;
    widget.route.handleUpdateBackGestureProgress(
      progress: 1 - backEvent.progress,
    );
  }

  @override
  void handleCancelBackGesture() {
    if (!_tracking) return;
    _tracking = false;
    widget.route.handleCancelBackGesture();
  }

  @override
  void handleCommitBackGesture() {
    if (!_tracking) return;
    _tracking = false;
    widget.route.handleCommitBackGesture();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
