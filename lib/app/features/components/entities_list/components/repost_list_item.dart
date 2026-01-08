// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/components/repost_author_header.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/components/article/article.dart';
import 'package:ion/app/features/feed/views/components/community_token_action/community_token_action.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/community_token_live.dart';
import 'package:ion/app/features/feed/views/components/post/post.dart';
import 'package:ion/app/features/feed/views/components/post/post_skeleton.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/typedefs/typedefs.dart';

class RepostListItem extends ConsumerWidget {
  const RepostListItem({
    required this.eventReference,
    this.onVideoTap,
    this.showNotInterested = true,
    this.plainInlineStyles = false,
    super.key,
  });

  final EventReference eventReference;
  final OnVideoTapCallback? onVideoTap;
  final bool showNotInterested;
  final bool plainInlineStyles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repostEntity = ref.watch(
          ionConnectEntityWithCountersProvider(eventReference: eventReference).select((value) {
            final entity = value.valueOrNull;
            if (entity != null) {
              ListCachedObjects.updateObject<IonConnectEntity>(context, entity);
            }
            return entity;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<IonConnectEntity>(context, eventReference);

    if (repostEntity == null) {
      return const Skeleton(child: PostSkeleton());
    }

    return GestureDetector(
      onTap: () => switch (repostEntity) {
        RepostEntity() =>
          PostDetailsRoute(eventReference: repostEntity.data.eventReference.encode())
              .push<void>(context),
        GenericRepostEntity()
            when [
              ModifiablePostEntity.kind,
              CommunityTokenDefinitionEntity.kind,
              CommunityTokenActionEntity.kind,
            ].any((kind) => repostEntity.data.kind == kind) =>
          PostDetailsRoute(eventReference: repostEntity.data.eventReference.encode())
              .push<void>(context),
        GenericRepostEntity() when repostEntity.data.kind == ArticleEntity.kind =>
          ArticleDetailsRoute(eventReference: repostEntity.data.eventReference.encode())
              .push<void>(context),
        _ => null,
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(start: 16.0.s),
            child: RepostAuthorHeader(pubkey: repostEntity.masterPubkey),
          ),
          switch (repostEntity) {
            RepostEntity() => Post(
                eventReference: repostEntity.data.eventReference,
                repostEventReference: eventReference,
                onVideoTap: onVideoTap,
                showNotInterested: showNotInterested,
                cache: false,
                plainInlineStyles: plainInlineStyles,
              ),
            GenericRepostEntity() when repostEntity.data.kind == ModifiablePostEntity.kind => Post(
                eventReference: repostEntity.data.eventReference,
                repostEventReference: eventReference,
                onVideoTap: onVideoTap,
                showNotInterested: showNotInterested,
                cache: false,
                plainInlineStyles: plainInlineStyles,
              ),
            GenericRepostEntity() when repostEntity.data.kind == ArticleEntity.kind => Padding(
                padding: EdgeInsetsDirectional.symmetric(vertical: 12.0.s) +
                    EdgeInsetsDirectional.only(end: 16.0.s),
                child: Article(
                  eventReference: repostEntity.data.eventReference,
                  addTrailingPadding: false,
                  showNotInterested: showNotInterested,
                  cache: false,
                ),
              ),
            GenericRepostEntity()
                when repostEntity.data.kind == CommunityTokenDefinitionEntity.kind =>
              CommunityTokenLive(
                eventReference: repostEntity.data.eventReference,
                network: true,
                headerOffset: 10.0.s,
              ),
            GenericRepostEntity() when repostEntity.data.kind == CommunityTokenActionEntity.kind =>
              CommunityTokenAction(
                eventReference: repostEntity.data.eventReference,
                network: true,
                headerOffset: 10.0.s,
              ),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}
