// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';

/// A base class for all network-related exceptions.
class NetworkException implements IONIdentityException {
  const NetworkException(this.message);

  @override
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// Represents an exception that occurs during the execution of a network request,
/// such as connection issues or request timeouts.
class RequestExecutionException extends NetworkException {
  RequestExecutionException(
    this.error,
    this.stackTrace, [
    String? message,
  ]) : super(message ?? 'Request execution failed');

  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() => 'RequestExecutionException: $message; error: $error';
}

/// Represents an exception due to an unexpected response format from the network request.
class ResponseFormatException extends NetworkException {
  const ResponseFormatException(this.response) : super('Unexpected response format');

  final dynamic response;

  @override
  String toString() => 'ResponseFormatException: Unexpected response format - $response';
}

/// Represents an exception that occurs during the decoding of a JSON response
/// into a Dart object.
class DecodeException extends NetworkException {
  const DecodeException(this.map, this.error, this.stackTrace) : super('Failed to decode response');

  final dynamic map;
  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() => 'DecodeException: Failed to decode response - $error\n$stackTrace';
}
