// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/event_count_request_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/providers/count_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'followers_count_provider.r.g.dart';

@riverpod
class FollowersCount extends _$FollowersCount {
  @override
  FutureOr<int?> build(
    String pubkey, {
    bool cache = true,
    bool network = true,
  }) async {
    final filters = [
      RequestFilter(
        kinds: const [FollowListEntity.kind],
        tags: {
          '#p': [pubkey],
        },
      ),
    ];

    try {
      return await ref.watch(
        countProvider(
          actionSource: ActionSourceUser(pubkey),
          requestData: EventCountRequestData(filters: filters),
          key: pubkey,
          type: EventCountResultType.followers,
          cache: cache,
          network: network,
        ).future,
      ) as FutureOr<int?>;
    } catch (error) {
      return null;
    }
  }

  void addOne() {
    if (!state.hasValue) return;
    final newValue = state.value! + 1;
    state = AsyncValue.data(newValue);
    _updateCache(newValue);
  }

  void removeOne() {
    if (!state.hasValue) return;
    final newValue = state.value! - 1;
    state = AsyncValue.data(newValue);
    _updateCache(newValue);
  }

  void _updateCache(int newCount) {
    final cacheKey = EventCountResultEntity.cacheKeyBuilder(
      key: pubkey,
      type: EventCountResultType.followers,
    );

    final cacheEntry =
        ref.read(ionConnectCacheProvider.select(cacheSelector<EventCountResultEntity>(cacheKey)));

    if (cacheEntry == null) {
      return;
    }

    ref.read(ionConnectCacheProvider.notifier).cache(
          cacheEntry.copyWith(data: cacheEntry.data.copyWith(content: newCount)),
        );
  }
}
