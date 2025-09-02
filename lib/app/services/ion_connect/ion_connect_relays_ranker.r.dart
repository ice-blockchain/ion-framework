// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/dio_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_relays_ranker.r.g.dart';

@riverpod
IonConnectRelaysRanker ionConnectRelaysRanker(Ref ref) {
  return IonConnectRelaysRanker(
    dio: ref.watch(dioProvider),
  );
}

final class IonConnectRelaysRanker {
  const IonConnectRelaysRanker({
    required this.dio,
  });

  final Dio dio;

  /// Ranks the relays based on their latency.
  ///
  /// Returns a List of MeasuredRelays sorted by their latency in ascending order (from best to worst).
  /// Emits results each time a relay is pinged.
  Stream<List<RankedRelay>> ranked(List<String> relaysUrls, {CancelToken? cancelToken}) {
    final resultsController = StreamController<List<RankedRelay>>();
    final measurements = <RankedRelay>[];
    var completedCount = 0;
    for (final relayUrl in relaysUrls) {
      _getRankedRelay(relayUrl, cancelToken).then(
        (result) {
          Logger.log('[RELAY] Relays ping results ${result.latency}');
          measurements
            ..add(result)
            ..sort((a, b) => a.latency.compareTo(b.latency));
          resultsController.add(List.from(measurements));
        },
      ).catchError(
        (Object? reason) {
          Logger.error(
            reason is Object ? reason : 'Unknown error',
            message: '[RELAY] Error pinging relay $relayUrl',
          );
        },
      ).whenComplete(() {
        completedCount++;
        if (completedCount == relaysUrls.length) {
          resultsController.close();
        }
      });
    }

    return resultsController.stream;
  }

  Future<RankedRelay> _getRankedRelay(
    String relayUrl, [
    CancelToken? cancelToken,
  ]) async {
    final stopWatch = Stopwatch()..start();
    try {
      final parsedRelayUrl = Uri.parse(relayUrl);
      final relayUri = Uri(
        scheme: 'https',
        host: parsedRelayUrl.host,
        port: parsedRelayUrl.hasPort ? parsedRelayUrl.port : null,
      );
      const timeout = Duration(seconds: 30);

      await dio.headUri<void>(
        relayUri,
        options: Options(
          headers: {
            'Accept': 'application/nostr+json',
          },
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
        cancelToken: cancelToken,
      );
      return RankedRelay(url: relayUrl, latency: stopWatch.elapsedMilliseconds);
    } catch (e) {
      return RankedRelay.unreachable(url: relayUrl);
    } finally {
      stopWatch.stop();
    }
  }
}

final class RankedRelay {
  const RankedRelay({
    required this.url,
    required this.latency,
  });

  const RankedRelay.unreachable({
    required this.url,
  }) : latency = -1;

  final String url;
  final int latency;

  bool get isReachable => latency >= 0;
}
