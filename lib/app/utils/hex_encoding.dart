// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

String bytesToHex(List<int> bytes) {
  final buffer = StringBuffer('0x');
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

List<int> hexToBytes(String hex) {
  var hexStr = hex.trim();
  if (hexStr.startsWith('0x')) {
    hexStr = hexStr.substring(2);
  }
  if (hexStr.length % 2 != 0) {
    hexStr = '0$hexStr';
  }
  final result = <int>[];
  for (var i = 0; i < hexStr.length; i += 2) {
    result.add(int.parse(hexStr.substring(i, i + 2), radix: 16));
  }
  return result;
}

List<int> getBytesFromAddress(String value) {
  if (value.startsWith('0x')) {
    return hexToBytes(value);
  }
  return utf8.encode(value);
}
