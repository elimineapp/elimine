import 'package:flutter/material.dart';

import '../core/appearance.dart';

/// The substance icon on a tinted circle, in the substance color.
class SubstanceBadge extends StatelessWidget {
  const SubstanceBadge({
    super.key,
    required this.color,
    required this.icon,
    this.size = 40,
  });

  final String color;
  final String icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.substanceColorOf(color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(substanceIcon(icon), color: c, size: size * 0.55),
    );
  }
}
