// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/event_count_request_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event_marker.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/user/providers/count_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replies_count_provider.r.g.dart';

@riverpod
class RepliesCount extends _$RepliesCount {
  @override
  Future<int> build(
    EventReference eventReference, {
    bool cache = true,
    bool network = false,
  }) async {
    final filters = [
      RequestFilter(
        kinds: const [
          PostEntity.kind,
          ModifiablePostEntity.kind,
        ],
        tags: Map.fromEntries([
          RelatedEvent.fromEventReference(
            eventReference,
            marker: RelatedEventMarker.reply,
          ).toFilterEntry(),
        ]),
      ),
    ];

    final count = await ref.watch(
      countProvider(
        key: eventReference.toString(),
        type: EventCountResultType.replies,
        requestData: EventCountRequestData(filters: filters),
        actionSource: ActionSourceUser(eventReference.masterPubkey),
        cache: cache,
        network: network,
      ).future,
    ) as int?;

    return count ?? 0;
  }

  void addOne() {
    state.whenData((count) {
      final newCount = count + 1;
      state = AsyncValue.data(newCount);
      _updateCache(eventReference, newCount);
    });
  }

  void removeOne() {
    state.whenData((count) {
      final newCount = count - 1;
      state = AsyncValue.data(newCount);
      _updateCache(eventReference, newCount);
    });
  }

  void _updateCache(EventReference eventReference, int newCount) {
    final cacheKey = EventCountResultEntity.cacheKeyBuilder(
      key: eventReference.toString(),
      type: EventCountResultType.replies,
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
