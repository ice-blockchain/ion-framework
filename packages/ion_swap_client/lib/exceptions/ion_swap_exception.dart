// SPDX-License-Identifier: ice License 1.0

class IonSwapException implements Exception {
  const IonSwapException([this.message, this.cause]);

  final String? message;
  final Exception? cause;

  @override
  String toString() => 'IonSwapException: $message, cause: $cause';
}

class IonSwapCoinPairNotFoundException extends IonSwapException {
  const IonSwapCoinPairNotFoundException()
      : super(
          'Ion swap coin pair not found',
        );
}
