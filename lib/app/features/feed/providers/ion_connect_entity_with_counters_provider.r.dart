// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_entity_with_counters_provider.r.g.dart';

@riverpod
IonConnectEntity? ionConnectEntityWithCounters(
  Ref ref, {
  required EventReference eventReference,
  bool network = true,
  bool cache = true,
}) {
  final currentUser = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (currentUser == null) {
    throw const CurrentUserNotFoundException();
  }

  // Do not query counters and deps if the entity if not a post or article (e.g. a repost)
  if (eventReference is! ReplaceableEventReference ||
      (eventReference.kind != ModifiablePostEntity.kind &&
          eventReference.kind != ArticleEntity.kind)) {
    return ref.watch(ionConnectSyncEntityProvider(eventReference: eventReference));
  }

  final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentUserPubkey == null) {
    throw const CurrentUserNotFoundException();
  }

  final search = SearchExtensions([
    ...SearchExtensions.withCounters(
      currentPubkey: currentUserPubkey,
      forKind: eventReference.kind,
    ).extensions,
  ]).toString();

  final hasCounterData = ref.read(ionConnectCacheProvider).containsKey(
    EventCountResultEntity.cacheKeyBuilder(
      key: eventReference.toString(),
      type: EventCountResultType.reactions,
    ),
  );

  if (!hasCounterData && network) {
    return ref.watch(
      ionConnectSyncEntityProvider(
        eventReference: eventReference,
        search: search,
        cache: false, 
      ),
    );
  }

  return ref.watch(
    ionConnectSyncEntityProvider(
      eventReference: eventReference,
      search: search,
      network: network,
      cache: cache,
    ),
  );
}
