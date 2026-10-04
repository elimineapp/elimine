import 'package:flutter/material.dart';

import '../core/appearance.dart';

/// The substance icon on a circle in the substance color: tinted, with the
/// icon in that color, or [filled], with the icon in a contrasting color.
class SubstanceBadge extends StatelessWidget {
  const SubstanceBadge({
    super.key,
    required this.color,
    required this.icon,
    this.size = 40,
    this.filled = false,
  });

  final String color;
  final String icon;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.substanceColorOf(color);
    final theme = Theme.of(context);
    final onFilled = theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : Colors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? c : c.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(
        substanceIcon(icon),
        color: filled ? onFilled : c,
        size: size * 0.55,
      ),
    );
  }
}
