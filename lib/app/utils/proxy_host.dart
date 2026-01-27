// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:convert/convert.dart' as convert;
import 'package:cryptography/dart.dart';

bool _isLowerHex(String s) {
  for (final unit in s.codeUnits) {
    final isDigit = unit >= 0x30 && unit <= 0x39; // 0-9
    final isLowerAtoF = unit >= 0x61 && unit <= 0x66; // a-f
    if (!isDigit && !isLowerAtoF) return false;
  }
  return true;
}

/// Builds a proxied hostname for an IP-based endpoint using the relay-proxy
/// scheme.
///
/// The resulting host is:
/// `<sha256(ip).hex.substring(0, 16)>.<domain>`
///
/// This mirrors the relay proxy URL format, so the same proxy domains can be
/// used for general connectivity checks as well.
String buildRelayProxyHostForIp({
  required String ip,
  required String domain,
}) {
  final hash = const DartSha256().hashSync(utf8.encode(ip));
  final hashHex = convert.hex.encode(hash.bytes);
  final normalizedIp = hashHex.substring(0, 16);
  return '$normalizedIp.$domain';
}

/// Builds a proxied hostname for BSC RPC access.
///
/// The resulting host is:
/// `bsc-rpc.<domain>`
///
/// This mirrors the RPC proxy URL format used across the app.
String buildBscRpcProxyHost({
  required String domain,
}) {
  final normalized = domain.trim();

  final firstDot = normalized.indexOf('.');
  if (firstDot > 0) {
    final firstLabel = normalized.substring(0, firstDot);
    if (firstLabel.length == 16 && _isLowerHex(firstLabel)) {
      return normalized;
    }
  }

  return 'bsc-rpc.$normalized';
}

Uri buildBscRpcProxyUri({
  required String domain,
}) {
  final host = buildBscRpcProxyHost(domain: domain);
  return Uri(scheme: 'https', host: host);
}
