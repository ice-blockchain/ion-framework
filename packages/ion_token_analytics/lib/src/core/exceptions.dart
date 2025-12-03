// SPDX-License-Identifier: ice License 1.0

class IonTokenAnalyticsException implements Exception {
  IonTokenAnalyticsException(this.message, {this.code});

  final String message;
  final int? code;

  @override
  String toString() => 'IonTokenAnalyticsException: $message (code: $code)';
}

class IonNetworkException extends IonTokenAnalyticsException {
  IonNetworkException(super.message, {super.code});
}

class IonServerException extends IonTokenAnalyticsException {
  IonServerException(super.message, {super.code});
}
