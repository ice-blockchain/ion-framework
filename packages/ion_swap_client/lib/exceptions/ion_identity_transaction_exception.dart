// SPDX-License-Identifier: ice License 1.0

/// Thrown when the Ion Identity transaction API fails (sign/broadcast, etc.).
/// Use this in [IonIdentityTransactionApi]; callers (swap, bridge, etc.) can
/// catch and map to their domain exception if needed.
class IonIdentityTransactionException implements Exception {
  const IonIdentityTransactionException([this.message, this.originalError]);

  final String? message;
  final Object? originalError;

  @override
  String toString() => 'IonIdentityTransactionException: $message';
}
