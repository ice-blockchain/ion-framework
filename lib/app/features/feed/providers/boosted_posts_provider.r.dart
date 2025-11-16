// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/boosted_post_info.f.dart';
import 'package:ion/app/features/feed/data/repository/boosted_posts_repository.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'boosted_posts_provider.r.g.dart';

@riverpod
class BoostedPosts extends _$BoostedPosts {
  // TODO: temporary storing and getting all data in local storage, until we got a BE ready

  @override
  FutureOr<Set<String>> build() async {
    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

    if (currentUserMasterPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final repository = ref.watch<BoostedPostsRepository>(boostedPostsRepositoryProvider);

    // Load both IDs and metadata
    final loadedIds = await repository.loadBoostedIds(currentUserMasterPubkey);
    final loadedMeta = await repository.loadBoostedMeta(currentUserMasterPubkey);

    // Filter out expired boosts
    final now = DateTime.now();
    final activeIds = <String>{};
    final activeMeta = <String, BoostPostData>{};

    for (final id in loadedIds) {
      final boostData = loadedMeta[id];
      if (boostData != null) {
        final endDate = boostData.purchasedAt.add(Duration(days: boostData.durationDays));
        if (endDate.isAfter(now)) {
          // Boost is still active
          activeIds.add(id);
          activeMeta[id] = boostData;
        }
      } else {
        // No metadata found, keep it for now (shouldn't happen, but be safe)
        activeIds.add(id);
      }
    }

    // If we removed any expired boosts, save the cleaned data
    if (activeIds.length != loadedIds.length || activeMeta.length != loadedMeta.length) {
      await repository.saveBoosted(
        currentUserMasterPubkey,
        ids: activeIds,
        meta: activeMeta,
      );
    }

    return activeIds;
  }

  Future<void> addBoostedPost(
    String eventReference,
    double cost,
    int durationDays,
  ) async {
    final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);

    if (currentUserMasterPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final repository = ref.read<BoostedPostsRepository>(boostedPostsRepositoryProvider);

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final currentSet = state.value ?? <String>{};
      final updatedSet = {...currentSet}..add(eventReference);

      final metaMap = await repository.loadBoostedMeta(currentUserMasterPubkey);
      final existing = metaMap[eventReference];
      if (existing != null) {
        metaMap[eventReference] = existing.copyWith(
          cost: existing.cost + cost,
        );
      } else {
        metaMap[eventReference] = BoostPostData(
          cost: cost,
          durationDays: durationDays,
          purchasedAt: DateTime.now(),
        );
      }

      await repository.saveBoosted(
        currentUserMasterPubkey,
        ids: updatedSet,
        meta: metaMap,
      );

      return updatedSet;
    });
  }

  bool isBoosted(String eventReference) {
    return state.value?.contains(eventReference) ?? false;
  }

  Future<BoostPostData?> getBoostData(String eventReference) async {
    final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);

    if (currentUserMasterPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final repository = ref.read<BoostedPostsRepository>(boostedPostsRepositoryProvider);
    final metaMap = await repository.loadBoostedMeta(currentUserMasterPubkey);
    return metaMap[eventReference];
  }
}

@riverpod
Future<BoostPostData?> boostedPostData(
  Ref ref,
  String eventReference,
) async {
  final notifier = ref.read(boostedPostsProvider.notifier);
  return notifier.getBoostData(eventReference);
}
