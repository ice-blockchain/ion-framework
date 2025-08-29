// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/counters/models/replied_events_map.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'replied_events_provider.r.g.dart';

@riverpod
class RepliedEvents extends _$RepliedEvents {
  @override
  Stream<Map<String, List<String>>> build() async* {
    keepAliveWhenAuthenticated(ref);

    final currentMasterPubkey = ref.watch(currentPubkeySelectorProvider);

    if (currentMasterPubkey == null) {
      yield const {};
      return;
    }
    var repliesForEventsMap = <String, List<String>>{};
    final cachedRepliesForEvents = ref.watch(
      ionConnectCacheProvider.select((cache) {
        final resultMap = _buildInitialMap(cache, currentMasterPubkey);
        return RepliesMap(resultMap);
      }),
    );
    repliesForEventsMap.addAll(cachedRepliesForEvents.replies);

    yield Map.unmodifiable(repliesForEventsMap);

    await for (final entity in ref.watch(ionConnectCacheStreamProvider)) {
      if (entity is! ModifiablePostEntity ||
          entity.data.parentEvent == null ||
          entity.masterPubkey != currentMasterPubkey) {
        continue;
      }

      final parentId = entity.data.parentEvent!.eventReference.toString();
      final updatedList = List<String>.from(repliesForEventsMap[parentId] ?? []);

      if (entity.isDeleted) {
        if (updatedList.remove(entity.id)) {
          repliesForEventsMap = Map<String, List<String>>.from(repliesForEventsMap)
            ..[parentId] = updatedList;
          yield Map.unmodifiable(repliesForEventsMap);
        }
      } else if (!updatedList.contains(entity.id)) {
        updatedList.add(entity.id);
        repliesForEventsMap = Map<String, List<String>>.from(repliesForEventsMap)
          ..[parentId] = updatedList;
        yield Map.unmodifiable(repliesForEventsMap);
      }
    }
  }
}

Map<String, List<String>> _buildInitialMap(
  Map<String, CacheEntry> cache,
  String currentUserMasterPubkey,
) {
  final result = <String, List<String>>{};

  for (final entry in cache.values) {
    final entity = entry.entity;
    if (entity is! ModifiablePostEntity ||
        entity.isDeleted ||
        entity.data.parentEvent == null ||
        entity.masterPubkey != currentUserMasterPubkey) {
      continue;
    }

    final parentId = entity.data.parentEvent!.eventReference.toString();
    result.putIfAbsent(parentId, () => []);
    if (!result[parentId]!.contains(entity.id)) {
      result[parentId]!.add(entity.id);
    }
  }

  return result;
}

@riverpod
bool isReplied(Ref ref, EventReference eventReference) {
  final repliedEventsMap = ref.watch(repliedEventsProvider).valueOrNull;
  final replyIds = repliedEventsMap?[eventReference.toString()];
  return replyIds?.isNotEmpty ?? false;
}
