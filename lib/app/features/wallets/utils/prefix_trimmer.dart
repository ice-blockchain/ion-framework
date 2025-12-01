// SPDX-License-Identifier: ice License 1.0

/// Used to trim the prefix from the value for TON transfers
/// from Ice Chrome extension
String _icePrefixTransfer = 'ton://transfer/';

String trimPrefix(
  String value, {
  String separator = ':',
}) {
  if (value.startsWith(_icePrefixTransfer)) {
    return value.substring(_icePrefixTransfer.length);
  }

  final parts = value.split(separator);
  if (parts.length == 1) {
    return parts.first;
  }
  return parts.skip(1).join(separator);
}
