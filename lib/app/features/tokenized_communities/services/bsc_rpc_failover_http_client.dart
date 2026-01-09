// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:ion/app/utils/logging.dart';
import 'package:web3dart/json_rpc.dart';

/// Persists the currently working RPC URL.
///
/// If [url] is `null`, the stored value should be cleared.
typedef PersistPreferredRpcUrl = FutureOr<void> Function(String? url);

/// An HTTP client that retries JSON-RPC requests across
/// multiple BSC RPC endpoints.
///
/// - Uses a preferred endpoint for all requests.
/// - If the preferred endpoint fails (transport error or 5xx/429/408),
///   it clears the preferred endpoint and immediately retries from the beginning
///   of the configured endpoint list.
/// - When an endpoint succeeds, it becomes the new preferred endpoint and is
///   persisted via [persistPreferredRpcUrl].
///
class BscRpcFailoverHttpClient extends http.BaseClient {
  BscRpcFailoverHttpClient({
    required List<Uri> endpoints,
    Uri? initialPreferred,
    http.Client? inner,
    PersistPreferredRpcUrl? persistPreferredRpcUrl,
  })  : _endpoints = List<Uri>.unmodifiable(endpoints),
        _inner = inner ?? http.Client(),
        _persistPreferredRpcUrl = persistPreferredRpcUrl,
        _preferred = initialPreferred;

  final List<Uri> _endpoints;
  final http.Client _inner;
  final PersistPreferredRpcUrl? _persistPreferredRpcUrl;

  Uri? _preferred;

  /// The best current RPC URL (preferred if set, otherwise the first endpoint).
  String get currentUrl {
    final preferred = _preferred;
    if (preferred != null) return preferred.toString();
    if (_endpoints.isEmpty) {
      throw StateError('No BSC RPC endpoints configured.');
    }
    return _endpoints.first.toString();
  }

  // Serializes preference updates to avoid races with concurrent requests.
  Future<void> _serial = Future<void>.value();

  @override
  void close() {
    _inner.close();
    super.close();
  }

  Future<T> _withSerial<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _serial = _serial.then((_) async {
      try {
        completer.complete(await action());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<void> _setPreferred(Uri? uri) async {
    _preferred = uri;
    final persist = _persistPreferredRpcUrl;
    if (persist == null) return;

    try {
      final res = persist(uri?.toString());
      if (res is Future) await res;
    } catch (_) {
      // Persistence failures should not break networking.
    }
  }

  bool _shouldFailoverStatus(int statusCode) {
    // Treat these as endpoint-level issues worth failing over:
    // - 5xx: server/proxy errors
    // - 408: request timeout
    // - 429: rate limit
    if (statusCode >= 500) return true;
    if (statusCode == 408) return true;
    if (statusCode == 429) return true;
    return false;
  }

  Future<Uint8List> _readBodyBytes(http.BaseRequest request) async {
    final builder = BytesBuilder(copy: false);
    final stream = request.finalize();
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  http.Request _cloneAsRequest(http.BaseRequest original, Uri newUri, Uint8List bodyBytes) {
    final req = http.Request(original.method, newUri);
    req.headers.addAll(original.headers);
    req
      ..bodyBytes = bodyBytes
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection;

    return req;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bodyBytes = await _readBodyBytes(request);

    // Build attempt order: preferred first, then full list (unique).
    final attemptOrder = <Uri>[];
    final seen = <String>{};

    final preferred = _preferred;
    if (preferred != null && seen.add(preferred.toString())) {
      attemptOrder.add(preferred);
    }
    for (final uri in _endpoints) {
      final key = uri.toString();
      if (seen.add(key)) attemptOrder.add(uri);
    }

    if (attemptOrder.isEmpty) {
      throw StateError('No BSC RPC endpoints configured.');
    }

    Object? lastError;
    StackTrace? lastStackTrace;
    http.StreamedResponse? lastResponse;

    for (var i = 0; i < attemptOrder.length; i++) {
      final endpoint = attemptOrder[i];
      final isPreferredAttempt =
          preferred != null && i == 0 && endpoint.toString() == preferred.toString();

      try {
        final req = _cloneAsRequest(request, endpoint, bodyBytes);
        final response = await _inner.send(req);

        if (_shouldFailoverStatus(response.statusCode)) {
          reportFailover(
            Exception(
              'BSC RPC failover: HTTP ${response.statusCode} from $endpoint',
            ),
            StackTrace.current,
            tag: 'bsc_rpc_failover_http_status',
          );

          // Drain so the underlying connection can be reused/closed cleanly.
          unawaited(response.stream.drain<void>());
          lastResponse = response;

          if (isPreferredAttempt) {
            // Preferred failed -> clear and restart from the beginning of the list.
            await _withSerial(() => _setPreferred(null));
          }
          continue;
        }

        // Success: mark as preferred immediately (so callers can read currentUrl right away),
        // then persist in the background.
        if (_preferred?.toString() != endpoint.toString()) {
          _preferred = endpoint;
          unawaited(_withSerial(() => _setPreferred(endpoint)));
        }
        return response;
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;

        reportFailover(
          Exception('BSC RPC failover: transport error from $endpoint: ${e.runtimeType}: $e'),
          st,
          tag: 'bsc_rpc_failover_transport_error',
        );

        if (isPreferredAttempt) {
          await _withSerial(() => _setPreferred(null));
        }
      }
    }

    // If we got responses but all were failover-worthy statuses, return the last.
    if (lastResponse != null) return lastResponse;

    // Otherwise, throw the last transport-level error.
    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace ?? StackTrace.current);
    }

    throw StateError('Failed to send request: unknown error.');
  }
}

class PreferredUrlJsonRpc extends JsonRPC {
  PreferredUrlJsonRpc({
    required String Function() urlProvider,
    required http.Client client,
  })  : _urlProvider = urlProvider,
        super('http://localhost', client);

  final String Function() _urlProvider;

  @override
  String get url => _urlProvider();
}
