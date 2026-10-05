import 'package:flutter/material.dart';

/// Durations and easing shared by every transition, so transitions of the
/// same kind move alike across the app.
abstract final class Motion {
  /// Fades, and every transition while animations are removed.
  static const short = Duration(milliseconds: 200);

  /// Tabs, the archive screen, the sheet and paging through periods.
  static const medium = Duration(milliseconds: 300);

  /// A surface growing into a screen or shrinking back.
  static const long = Duration(milliseconds: 400);

  /// For things entering or growing, and their exit counterpart.
  static const emphasized = Easing.emphasizedDecelerate;
  static const emphasizedExit = Easing.emphasizedAccelerate;

  /// For a surface growing into a screen and shrinking back.
  static const transform = Curves.easeInOutCubicEmphasized;

  /// For things that stay on screen while they change.
  static const standard = Easing.standard;

  /// Whether the system asks for animations to be removed: transitions then
  /// fade quickly instead of moving or scaling.
  static bool reducedOf(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
