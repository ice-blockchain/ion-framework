// SPDX-License-Identifier: ice License 1.0

import 'package:async/async.dart';
import 'package:ion/app/features/feed/create_article/providers/create_article_provider.r.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/providers/repost_notifier.r.dart';
import 'package:ion/app/features/feed/providers/user_posts_data_source_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_posts_provider.r.g.dart';

@riverpod
class UserPosts extends _$UserPosts with DelegatedPagedNotifier {
  @override
  ({Iterable<IonConnectEntity>? items, bool hasMore}) build(String pubkey) {
    final postsStream = ref.watch(createPostNotifierStreamProvider);
    final articlesStream = ref.watch(createArticleNotifierStreamProvider);
    final repostsStream = ref.watch(createRepostNotifierStreamProvider);
    final subscription = StreamGroup.merge([postsStream, articlesStream, repostsStream])
        .where((entity) => _filterUserEntities(entity, pubkey))
        .distinct()
        .listen(insertEntity);
    ref.onDispose(subscription.cancel);

    final dataSources = ref.watch(userPostsDataSourceProvider(pubkey));
    if (dataSources == null) {
      return (items: null, hasMore: false);
    }

    final data = ref.watch(entitiesPagedDataProvider(dataSources));
    if (data == null) {
      return (items: null, hasMore: false);
    }

    return (items: data.data.items, hasMore: data.hasMore);
  }

  @override
  PagedNotifier getDelegate() {
    final dataSources = ref.read(userPostsDataSourceProvider(pubkey));
    if (dataSources == null) {
      throw StateError('Data sources not available for user posts');
    }
    return ref.read(entitiesPagedDataProvider(dataSources).notifier);
  }

  bool _filterUserEntities(IonConnectEntity entity, String targetPubkey) {
    if (entity.masterPubkey != targetPubkey) {
      return false;
    }

    return (entity is ModifiablePostEntity &&
            entity.data.parentEvent == null &&
            entity.data.expiration == null) ||
        entity is GenericRepostEntity ||
        (entity is PostEntity &&
            entity.data.parentEvent == null &&
            entity.data.expiration == null) ||
        entity is RepostEntity ||
        entity is ArticleEntity;
  }
}
