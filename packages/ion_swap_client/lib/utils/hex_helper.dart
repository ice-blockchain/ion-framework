// SPDX-License-Identifier: ice License 1.0

import 'dart:typed_data';

class HexHelper {
  HexHelper._();

  static String bytesToHex(List<int> bytes) {
    final buffer = StringBuffer('0x');
    for (final value in bytes) {
      buffer.write(value.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static Uint8List hexToBytes(String hex) {
    final cleanHex = hex.startsWith('0x') ? hex.substring(2) : hex;
    return Uint8List.fromList(
      List.generate(
        cleanHex.length ~/ 2,
        (i) => int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }
}
