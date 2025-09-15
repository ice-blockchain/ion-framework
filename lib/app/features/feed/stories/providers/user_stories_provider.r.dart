// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/feed_data_source_builders.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
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

    return data;
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
