// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event_marker.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_posts_data_source_provider.r.g.dart';

const requestKinds = [
  ModifiablePostEntity.kind,
  PostEntity.kind,
  RepostEntity.kind,
  ArticleEntity.kind,
  GenericRepostEntity.modifiablePostRepostKind,
  GenericRepostEntity.articleRepostKind,
  GenericRepostEntity.communityTokenDefinitionRepostKind,
  GenericRepostEntity.communityTokenActionRepostKind,
  CommunityTokenActionEntity.kind,
];

const withCountersKinds = [
  ModifiablePostEntity.kind,
  PostEntity.kind,
  ArticleEntity.kind,
  RepostEntity.kind,
  GenericRepostEntity.kind,
  CommunityTokenActionEntity.kind,
];

const withTokensKinds = [
  ModifiablePostEntity.kind,
  PostEntity.kind,
  ArticleEntity.kind,
  RepostEntity.kind,
  GenericRepostEntity.kind,
];

@riverpod
List<EntitiesDataSource>? userPostsDataSource(Ref ref, String pubkey) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentPubkey == null) {
    return null;
  }

  final search = SearchExtensions([
    ...[
      for (final kind in withCountersKinds)
        ...SearchExtensions.withCounters(forKind: kind, currentPubkey: currentPubkey).extensions,
    ],
    ...[
      for (final kind in withTokensKinds) ...SearchExtensions.withTokens(forKind: kind).extensions,
    ],
    TagMarkerSearchExtension(
      tagName: RelatedReplaceableEvent.tagName,
      marker: RelatedEventMarker.reply.toShortString(),
      negative: true,
    ),
    TagMarkerSearchExtension(
      tagName: RelatedImmutableEvent.tagName,
      marker: RelatedEventMarker.reply.toShortString(),
      negative: true,
    ),
    ExpirationSearchExtension(expiration: false),
  ]).toString();

  return [
    EntitiesDataSource(
      actionSource: ActionSourceUser(pubkey),
      entityFilter: (entity) =>
          entity.masterPubkey == pubkey &&
          ((entity is ModifiablePostEntity && entity.data.parentEvent == null) ||
              entity is ArticleEntity ||
              entity is GenericRepostEntity ||
              (entity is PostEntity && entity.data.parentEvent == null) ||
              entity is RepostEntity ||
              entity is CommunityTokenDefinitionEntity ||
              entity is CommunityTokenActionEntity),
      requestFilter: RequestFilter(
        kinds: requestKinds,
        authors: [pubkey],
        search: search,
        limit: 10,
      ),
    ),
  ];
}
