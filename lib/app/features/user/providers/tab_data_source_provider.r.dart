// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/user_articles_data_source_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_holdings_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_posts_data_source_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_posts_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_replies_data_source_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_videos_data_source_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/model/tab_entity_type.dart';
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
    case TabEntityType.holdings:
      // Holdings uses the same data source as posts (filtering happens at provider level)
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
    case TabEntityType.holdings:
      return ref.watch(userHoldingsProvider(pubkey));
    case TabEntityType.articles:
    case TabEntityType.replies:
    case TabEntityType.videos:
      final dataSource = ref.watch(tabDataSourceProvider(type: type, pubkey: pubkey));
      if (dataSource == null) {
        return (items: null, hasMore: false);
      }
      final entitiesPagedData = ref.watch(entitiesPagedDataProvider(dataSource));
      if (entitiesPagedData == null) {
        return (items: null, hasMore: false);
      }
      return (items: entitiesPagedData.data.items, hasMore: entitiesPagedData.hasMore);
  }
}
