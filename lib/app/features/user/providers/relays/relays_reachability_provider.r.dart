// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relays_reachability_provider.r.g.dart';

final class RelayReachabilityInfo {
  const RelayReachabilityInfo({
    required this.relayUrl,
    required this.failedToReachCount,
    required this.lastFailedToReachDate,
  });

  final String relayUrl;
  final int failedToReachCount;
  final DateTime lastFailedToReachDate;

  bool get isUnreachable => failedToReachCount >= 3;
}

@riverpod
class RelayReachability extends _$RelayReachability {
  @override
  FutureOr<void> build() async {}

  RelayReachabilityInfo? get(String relayUrl) {
    final localStorage = ref.read(localStorageProvider);

    final key = _getKey(relayUrl);
    final reachabilityInfo = localStorage.getStringList(key);
    if (reachabilityInfo == null || reachabilityInfo.isEmpty) {
      return null;
    }
    final failedToReachCount = int.parse(reachabilityInfo[0]);
    final lastFailedToReachDate = DateTime.parse(reachabilityInfo[1]);
    return RelayReachabilityInfo(
      relayUrl: relayUrl,
      failedToReachCount: failedToReachCount,
      lastFailedToReachDate: lastFailedToReachDate,
    );
  }

  List<RelayReachabilityInfo> getAll(List<String> relayUrls) {
    return relayUrls.map(get).nonNulls.toList();
  }

  UserRelaysEntity? getFilteredRelayEntity(UserRelaysEntity relaysEntity) {
    final reachableRelays = _filterReachableRelays(relaysEntity.data.list);
    if (reachableRelays == null) {
      return null;
    }

    return relaysEntity.copyWith(
      data: UserRelaysData(
        list: reachableRelays,
      ),
    );
  }

  Future<void> save(RelayReachabilityInfo relayReachabilityInfo) {
    final localStorage = ref.read(localStorageProvider);
    final key = _getKey(relayReachabilityInfo.relayUrl);
    return localStorage.setStringList(
      key,
      [
        relayReachabilityInfo.failedToReachCount.toString(),
        relayReachabilityInfo.lastFailedToReachDate.toIso8601String(),
      ],
    );
  }

  Future<void> clear(String relayUrl) {
    final localStorage = ref.read(localStorageProvider);
    final key = _getKey(relayUrl);
    return localStorage.remove(key);
  }

  String _getKey(String relayUrl) {
    return 'relay_reachability_info_$relayUrl';
  }

  List<UserRelay>? _filterReachableRelays(List<UserRelay> relaysList) {
    final reachabilityInfoNotifier = ref.read(relayReachabilityProvider.notifier);
    final reachabilityInfos = relaysList
        .map((relay) => reachabilityInfoNotifier.get(relay.url))
        .whereType<RelayReachabilityInfo>();
    final deadRelays =
        reachabilityInfos.where((reachabilityInfo) => reachabilityInfo.isUnreachable).toList();

    // needs refresh when 50% + 1 or more are dead
    if (deadRelays.length >= (relaysList.length / 2 + 1).floor()) {
      return null;
    }

    return relaysList
        .where((relay) => deadRelays.none((deadRelay) => deadRelay.relayUrl == relay.url))
        .toList();
  }
}
