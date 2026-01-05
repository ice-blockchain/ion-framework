// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/providers/user_posts_data_source_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_holdings_provider.r.g.dart';

@riverpod
class UserHoldings extends _$UserHoldings with DelegatedPagedNotifier {
  @override
  ({Iterable<IonConnectEntity>? items, bool hasMore}) build(String pubkey) {
    final dataSources = ref.watch(userPostsDataSourceProvider(pubkey));
    if (dataSources == null) {
      return (items: null, hasMore: false);
    }

    final data = ref.watch(entitiesPagedDataProvider(dataSources));
    if (data == null) {
      return (items: null, hasMore: false);
    }

    final allItems = data.data.items;
    if (allItems == null) {
      return (items: null, hasMore: data.hasMore);
    }

    // Filter to include only tokenized community entities
    final holdingsItems = allItems.where(_isTokenizedCommunityEntity);

    // If filtered items are empty but we've loaded data, show empty state
    // (set hasMore to false to prevent infinite loading)
    final hasMore = holdingsItems.isNotEmpty && data.hasMore;

    return (items: holdingsItems, hasMore: hasMore);
  }

  @override
  PagedNotifier getDelegate() {
    final dataSources = ref.read(userPostsDataSourceProvider(pubkey));
    if (dataSources == null) {
      throw StateError('Data sources not available for user holdings');
    }
    return ref.read(entitiesPagedDataProvider(dataSources).notifier);
  }

  bool _isTokenizedCommunityEntity(IonConnectEntity entity) {
    return entity is CommunityTokenActionEntity ||
        entity is CommunityTokenDefinitionEntity ||
        (entity is GenericRepostEntity &&
            (entity.data.kind == GenericRepostEntity.communityTokenDefinitionRepostKind ||
                entity.data.kind == GenericRepostEntity.communityTokenActionRepostKind));
  }
}
