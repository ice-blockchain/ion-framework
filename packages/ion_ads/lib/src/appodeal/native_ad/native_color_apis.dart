// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

extension ColorToHex on Color {
  String toHex() {
    final hex = toARGB32().toRadixString(16).toUpperCase();
    return "#${hex.padLeft(8, '0')}"; // Pad with zeros to get the #AARRGGBB format
  }
}
