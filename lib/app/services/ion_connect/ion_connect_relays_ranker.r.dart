// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/model/relay_info.f.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_info_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_relays_ranker.r.g.dart';

@riverpod
IonConnectRelaysRanker ionConnectRelaysRanker(Ref ref) {
  return IonConnectRelaysRanker(
    /// Returns nip-11 data for the given relay URL.
    ///
    /// Using provider instead of the underlying repository to cache the result for the future use.
    getRelayInfo: ({required String relayUrl}) async =>
        ref.refresh(relayInfoProvider(relayUrl).future),
  );
}

final class IonConnectRelaysRanker {
  const IonConnectRelaysRanker({
    required this.getRelayInfo,
  });

  final Future<RelayInfo> Function({required String relayUrl}) getRelayInfo;

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
          Logger.log('[RELAY] Ranking. Relays ping results ${result.latency}');
          measurements
            ..add(result)
            ..sort((a, b) => a.latency.compareTo(b.latency));
          resultsController.add(List.from(measurements));
        },
      ).catchError(
        (Object? reason) {
          Logger.error(
            reason is Object ? reason : 'Unknown error',
            message: '[RELAY] Ranking. Error pinging relay $relayUrl',
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
      const timeout = Duration(seconds: 30);
      final relayInfo = await getRelayInfo(relayUrl: relayUrl).timeout(timeout);
      if (relayInfo case RelayInfo(:final systemStatuses?)) {
        // Do not check sendingPushNotifications system intentionally
        final requiredSystems = [
          systemStatuses.publishingEvents,
          systemStatuses.subscribingForEvents,
          systemStatuses.dvm,
          systemStatuses.uploadingFiles,
          systemStatuses.readingFiles,
        ];
        if (requiredSystems.any((status) => status != RelaySystemStatus.up)) {
          return RankedRelay.unreachable(url: relayUrl);
        }
      }
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
