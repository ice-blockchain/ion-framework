// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/user_articles_data_source_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_posts_data_source_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_posts_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_replies_data_source_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_videos_data_source_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/extensions/user_pinned_entity_extension.dart';
import 'package:ion/app/features/user/model/tab_entity_type.dart';
import 'package:ion/app/features/user/providers/user_pinned_content_provider.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tab_data_source_provider.r.g.dart';

@riverpod
List<EntitiesDataSource>? tabDataSource(
  Ref ref, {
  required TabEntityType type,
  required String pubkey,
}) {
  switch (type) {
    case TabEntityType.posts:
      return ref.watch(userPostsDataSourceProvider(pubkey));
    case TabEntityType.articles:
      return ref.watch(userArticlesDataSourceProvider(pubkey));
    case TabEntityType.replies:
      return ref.watch(userRepliesDataSourceProvider(pubkey));
    case TabEntityType.videos:
      return ref.watch(userVideosDataSourceProvider(pubkey));
  }
}

@riverpod
({Iterable<IonConnectEntity>? items, bool hasMore}) tabEntitiesData(
  Ref ref, {
  required TabEntityType type,
  required String pubkey,
}) {
  switch (type) {
    case TabEntityType.posts:
      return ref.watch(userPostsProvider(pubkey));
    case TabEntityType.articles:
    case TabEntityType.replies:
    case TabEntityType.videos:
      final dataSource = ref.watch(tabDataSourceProvider(type: type, pubkey: pubkey));
      if (dataSource == null) {
        return (items: null, hasMore: false);
      }
      final entitiesPagedData = ref.watch(entitiesPagedDataProvider(dataSource));
      final items = entitiesPagedData?.data.items;
      if (entitiesPagedData == null || items == null) {
        return (items: null, hasMore: false);
      }

      final pinnedContentKey = ref.watch(pinnedContentKeyProvider(type.name));
      final sortedItems = items.sortedByPinnedKey(pinnedContentKey);
      return (items: sortedItems, hasMore: entitiesPagedData.hasMore);
  }
}
