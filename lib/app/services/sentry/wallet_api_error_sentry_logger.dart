// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/services/sentry/api_error_sentry_logger.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';

Future<void> logWalletApiErrorToSentry(
  Object error, {
  required String tag,
  required String operation,
  required String endpoint,
  StackTrace? stackTrace,
  Map<String, String>? tags,
  Map<String, dynamic>? debugContext,
}) async {
  try {
    final rootError = _unwrapError(error);
    final cause = extractApiErrorCause(rootError);
    final sentryTags = <String, String>{
      'wallet_operation': operation,
      'wallet_endpoint': endpoint,
      if (tags != null) ...tags,
    };

    final context = <String, dynamic>{
      'operation': operation,
      'endpoint': endpoint,
      'exceptionType': error.runtimeType.toString(),
      'cause': cause,
      ...extractApiErrorNetworkContext(rootError),
      ..._extractErrorDebugContext(error),
      if (debugContext != null) ...debugContext,
    };

    await SentryService.logException(
      error,
      stackTrace: stackTrace,
      tag: tag,
      tags: sentryTags,
      debugContext: context,
    );
  } catch (_) {
    // Logging must never break the user flow.
  }
}

Object _unwrapError(Object error) {
  if (error is DebugContextException && error.originalError != null) {
    return error.originalError!;
  }

  return error;
}

Map<String, dynamic> _extractErrorDebugContext(Object error) {
  if (error is DebugContextException) {
    return error.debugContext;
  }

  return const {};
}

Future<Object?> logWalletApiErrorStateTransitionToSentry<T>(
  AsyncValue<T>? previous,
  AsyncValue<T> next, {
  required String tag,
  required String operation,
  required String endpoint,
  Set<Type> excludedErrorTypes = const {},
  bool Function(Object error)? shouldLog,
  Map<String, String>? tags,
  Map<String, dynamic>? debugContext,
}) async {
  if (previous?.isLoading != true || next.isLoading || !next.hasError) {
    return null;
  }

  final error = next.error;
  if (error == null || excludedErrorTypes.contains(error.runtimeType)) {
    return null;
  }
  if (shouldLog != null && !shouldLog(error)) {
    return null;
  }

  await logWalletApiErrorToSentry(
    error,
    stackTrace: next.stackTrace,
    tag: tag,
    operation: operation,
    endpoint: endpoint,
    tags: tags,
    debugContext: debugContext,
  );

  return error;
}
