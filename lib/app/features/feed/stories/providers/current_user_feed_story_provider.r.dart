// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/feed_data_source_builders.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_user_feed_story_provider.r.g.dart';

@riverpod
class CurrentUserFeedStory extends _$CurrentUserFeedStory {
  @override
  ModifiablePostEntity? build() {
    keepAliveWhenAuthenticated(ref);
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentPubkey == null) {
      return null;
    }
    final dataSources = ref.watch(currentUserFeedStoryDataSourceProvider);
    if (dataSources == null) {
      return null;
    }

    return ref
        .watch(entitiesPagedDataProvider(dataSources))
        ?.data
        .items
        ?.whereType<ModifiablePostEntity>()
        .where((story) => !story.isDeleted)
        .firstOrNull;
  }

  void refresh() {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentPubkey != null) {
      ref.invalidate(currentUserFeedStoryDataSourceProvider);
    }
  }
}

@riverpod
List<EntitiesDataSource>? currentUserFeedStoryDataSource(Ref ref) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentPubkey == null) {
    return null;
  }
  return [
    buildStoriesDataSource(
      actionSource: const ActionSource.currentUser(),
      authors: [currentPubkey],
      currentPubkey: currentPubkey,
      searchExtensions: [StoriesCountSearchExtension()],
    ).dataSource,
  ];
}
