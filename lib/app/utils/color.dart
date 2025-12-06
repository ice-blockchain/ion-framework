// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

String toHexColor(Color color) {
  return '#${(color.r * 255).toInt().toRadixString(16).padLeft(2, '0')}'
      '${(color.g * 255).toInt().toRadixString(16).padLeft(2, '0')}'
      '${(color.b * 255).toInt().toRadixString(16).padLeft(2, '0')}';
}

Color fromHexColor(String hexString) {
  final hex = hexString.replaceAll('#', '');
  return Color(int.parse('0xff$hex'));
}

// Determines if a color is dark based on luminance
// Luminance ranges from 0 (dark) to 1 (light)
bool isColorDark(Color color) {
  return color.computeLuminance() < 0.5;
}
