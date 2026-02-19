// SPDX-License-Identifier: ice License 1.0

class IonSwapException implements Exception {
  const IonSwapException([this.message, this.originalError]);

  final String? message;
  final Object? originalError;

  @override
  String toString() => 'IonSwapException: $message, originalError: $originalError';
}

class IonSwapCoinPairNotFoundException extends IonSwapException {
  const IonSwapCoinPairNotFoundException()
      : super(
          'Ion swap coin pair not found',
        );
}
