// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/feed_data_source_builders.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_stories_provider.r.g.dart';

@riverpod
class UserStories extends _$UserStories {
  @override
  Iterable<ModifiablePostEntity>? build(String pubkey) {
    final dataSources = ref.watch(userStoriesDataSourceProvider(pubkey: pubkey));
    if (dataSources == null) {
      return null;
    }

    final data = ref
        .watch(entitiesPagedDataProvider(dataSources))
        ?.data
        .items
        ?.whereType<ModifiablePostEntity>()
        .toList()
        .reversed
        .toList();

    if (data == null || data.isEmpty) return null;

    final addIndexes = _generateAdIndexes(data);
    for (final index in addIndexes) {
      data.insert(
        index,
        data[index].copyWith(id: '${data[index].id}_ad'),
      );
    }
    Logger.log('addIndexes :$addIndexes, final data size: ${data.length}');

    return data;
  }

  List<int> _generateAdIndexes(List<ModifiablePostEntity> data) {
    final adIndices = <int>[];

    final rng = Random(data.length); // Seed with length to keep it consistent-ish per load

    // Start: 5 + random (0..4)
    var currentIndex = 1 + rng.nextInt(5);

    while (currentIndex < data.length) {
      adIndices.add(currentIndex);

      // Next interval: 5 +/- random.
      // Let's say random is -2 to +2.
      // Formula: 5 + (0..4) - 2 => 3..7
      var interval = 5 + rng.nextInt(5) - 2;

      // Enforce not often than 3
      if (interval < 3) interval = 3;

      currentIndex += interval + 1; // +1 to account for the ad itself effectively occupying a slot
    }

    return adIndices;
  }

  void removeStory(String id) {
    state = state?.where((story) => story.data.replaceableEventId.value != id);
  }
}

@riverpod
List<EntitiesDataSource>? userStoriesDataSource(
  Ref ref, {
  required String pubkey,
  int limit = 100,
}) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentPubkey == null) {
    return null;
  }
  return [
    buildStoriesDataSource(
      actionSource: ActionSource.user(pubkey),
      authors: [pubkey],
      currentPubkey: currentPubkey,
      limit: limit,
    ).dataSource,
  ];
}
