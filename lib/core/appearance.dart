import 'package:flutter/material.dart';

/// Colors and icons users pick for substances. Stored by key, so keys must
/// never change; values can be tuned freely. The palette is kept small and
/// well separated so stacked charts stay readable.
const substanceColors = <String, Color>{
  'green': Color(0xFF4CAF7A),
  'teal': Color(0xFF26A69A),
  'sky': Color(0xFF4FA3E0),
  'indigo': Color(0xFF7986CB),
  'violet': Color(0xFFAB7BE0),
  'pink': Color(0xFFE57BA8),
  'red': Color(0xFFE5735F),
  'orange': Color(0xFFF0954A),
  'amber': Color(0xFFE6C04A),
  'slate': Color(0xFF90A4AE),
};

const substanceIcons = <String, IconData>{
  'pill': Icons.medication_outlined,
  'syringe': Icons.vaccines_outlined,
  'drop': Icons.water_drop_outlined,
  'powder': Icons.grain_outlined,
  'leaf': Icons.eco_outlined,
  'smoke': Icons.smoking_rooms_outlined,
  'air': Icons.air_outlined,
  'coffee': Icons.local_cafe_outlined,
  'drink': Icons.local_bar_outlined,
  'sun': Icons.wb_sunny_outlined,
  'moon': Icons.bedtime_outlined,
  'bolt': Icons.bolt_outlined,
  'mind': Icons.psychology_outlined,
  'heart': Icons.favorite_border,
  'science': Icons.science_outlined,
  'spa': Icons.spa_outlined,
  'star': Icons.star_border,
  'circle': Icons.circle_outlined,
};

Color substanceColor(String key) =>
    substanceColors[key] ?? substanceColors.values.first;

IconData substanceIcon(String key) =>
    substanceIcons[key] ?? substanceIcons.values.first;
