// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_provider.r.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/follow_list_state.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'follow_list_provider.r.g.dart';

const _kFollowListLimit = 50;

@riverpod
class CurrentUserFollowListWithMetadata extends _$CurrentUserFollowListWithMetadata {
  late final List<String> _allPubkeys;

  @override
  Future<CurrentUserFollowListWithMetadataState> build() async {
    final followListEntity = await ref.watch(currentUserFollowListProvider.future);
    _allPubkeys = followListEntity?.data.list.map((e) => e.pubkey).toList() ?? [];

    final initialPubkeys = _allPubkeys.take(_kFollowListLimit).toList();

    _fetchMetadata(initialPubkeys);

    return CurrentUserFollowListWithMetadataState(
      pubkeys: initialPubkeys,
      hasMore: initialPubkeys.length < _allPubkeys.length,
    );
  }

  Future<void> fetchEntities() async {
    if (state.isLoading || !state.hasValue || !state.value!.hasMore) {
      return;
    }

    final previousState = state.value!;
    state = AsyncData(previousState.copyWith(hasMore: false)); // to prevent concurrent fetches

    final currentPubkeys = previousState.pubkeys;

    final nextPubkeys = _allPubkeys.skip(currentPubkeys.length).take(_kFollowListLimit).toList();

    if (nextPubkeys.isEmpty) {
      state = AsyncData(previousState.copyWith(hasMore: false));
      return;
    }

    _fetchMetadata(nextPubkeys);

    final newPubkeys = [...currentPubkeys, ...nextPubkeys];
    state = AsyncData(
      previousState.copyWith(
        pubkeys: newPubkeys,
        hasMore: newPubkeys.length < _allPubkeys.length,
      ),
    );
  }

  void _fetchMetadata(List<String> pubkeys) {
    if (pubkeys.isEmpty) {
      return;
    }

    unawaited(
      ref.read(ionConnectEntitiesManagerProvider.notifier).fetch(
            eventReferences: pubkeys
                .map(
                  (masterPubkey) => ReplaceableEventReference(
                    masterPubkey: masterPubkey,
                    kind: UserMetadataEntity.kind,
                  ),
                )
                .toList(),
            search: ProfileBadgesSearchExtension(forKind: UserMetadataEntity.kind).toString(),
          ),
    );
  }
}

@riverpod
Future<FollowListEntity?> followList(
  Ref ref,
  String pubkey, {
  bool network = true,
  bool cache = true,
}) async {
  return await ref.watch(
    ionConnectEntityProvider(
      cache: cache,
      network: network,
      eventReference: ReplaceableEventReference(masterPubkey: pubkey, kind: FollowListEntity.kind),
    ).future,
  ) as FollowListEntity?;
}

@riverpod
FollowListEntity? currentUserSyncFollowList(Ref ref) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentPubkey == null) {
    return null;
  }
  return ref.watch(
    ionConnectSyncEntityProvider(
      eventReference:
          ReplaceableEventReference(masterPubkey: currentPubkey, kind: FollowListEntity.kind),
    ),
  ) as FollowListEntity?;
}

@riverpod
Future<FollowListEntity?> currentUserFollowList(Ref ref) async {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentPubkey == null) {
    return null;
  }
  return ref.watch(followListProvider(currentPubkey).future);
}

@riverpod
bool isCurrentUserFollowingSelector(Ref ref, String pubkey) {
  final optimistic = ref.watch(followWatchProvider(pubkey)).valueOrNull;
  if (optimistic != null) {
    return optimistic.following;
  }

  return ref.watch(
    currentUserFollowListProvider.select(
      (state) => state.valueOrNull?.data.list.any((followee) => followee.pubkey == pubkey) ?? false,
    ),
  );
}

@riverpod
bool isCurrentUserFollowed(Ref ref, String pubkey, {bool cache = true}) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  return ref.watch(
    followListProvider(pubkey, cache: cache).select(
      (state) =>
          state.valueOrNull?.data.list.any((followee) => followee.pubkey == currentPubkey) ?? false,
    ),
  );
}
