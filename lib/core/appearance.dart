import 'package:flutter/material.dart';

/// Colors users pick for substances, in the fixed order new substances take
/// them. Each hue has its own step for light and dark surfaces. This is a
/// validated categorical palette: neighbours in this order stay apart for
/// colour-blind readers, which matters because stacked charts put substances
/// next to each other in palette order.
///
/// Stored by key, so keys must never change.
const substanceColors = <String, ({Color light, Color dark})>{
  'blue': (light: Color(0xFF2A78D6), dark: Color(0xFF3987E5)),
  'orange': (light: Color(0xFFEB6834), dark: Color(0xFFD95926)),
  'aqua': (light: Color(0xFF1BAF7A), dark: Color(0xFF199E70)),
  'yellow': (light: Color(0xFFEDA100), dark: Color(0xFFC98500)),
  'magenta': (light: Color(0xFFE87BA4), dark: Color(0xFFD55181)),
  'green': (light: Color(0xFF008300), dark: Color(0xFF008300)),
  'violet': (light: Color(0xFF4A3AA7), dark: Color(0xFF9085E9)),
  'red': (light: Color(0xFFE34948), dark: Color(0xFFE66767)),
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

/// Position in the palette; unknown keys sort last.
int substanceColorOrder(String key) {
  final i = substanceColors.keys.toList().indexOf(key);
  return i < 0 ? substanceColors.length : i;
}

Color substanceColor(String key, Brightness brightness) {
  final c = substanceColors[key] ?? substanceColors.values.first;
  return brightness == Brightness.dark ? c.dark : c.light;
}

IconData substanceIcon(String key) =>
    substanceIcons[key] ?? substanceIcons.values.first;

extension SubstanceColorContext on BuildContext {
  Color substanceColorOf(String key) =>
      substanceColor(key, Theme.of(this).brightness);
}
