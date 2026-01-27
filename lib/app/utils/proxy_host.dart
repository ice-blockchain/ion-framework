// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:convert/convert.dart' as convert;
import 'package:cryptography/dart.dart';

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

Uri buildBscRpcProxyUri({
  required String domain,
}) {
  return Uri(scheme: 'https', host: domain);
}
