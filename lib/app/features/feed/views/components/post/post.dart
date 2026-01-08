// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/counter_items_footer/counter_items_footer.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/components/parent_entity.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/components/article/article.dart';
import 'package:ion/app/features/feed/views/components/bottom_sheet_menu/content_bottom_sheet_menu.dart';
import 'package:ion/app/features/feed/views/components/community_token_action/components/community_token_action_body.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/community_token_live_body.dart';
import 'package:ion/app/features/feed/views/components/deleted_entity/deleted_entity.dart';
import 'package:ion/app/features/feed/views/components/post/components/post_body/post_body.dart';
import 'package:ion/app/features/feed/views/components/post/post_skeleton.dart';
import 'package:ion/app/features/feed/views/components/quoted_entity_frame/quoted_entity_frame.dart';
import 'package:ion/app/features/feed/views/components/time_ago/time_ago.dart';
import 'package:ion/app/features/feed/views/components/user_info/user_info.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/typedefs/typedefs.dart';

class Post extends ConsumerWidget {
  const Post({
    required this.eventReference,
    this.repostEventReference,
    this.timeFormat = TimestampFormat.short,
    this.displayQuote = true,
    this.displayParent = false,
    this.topOffset,
    this.headerOffset,
    this.header,
    this.footer,
    this.quotedEventFooter,
    this.onDelete,
    this.isAccentTheme = false,
    this.isTextSelectable = false,
    this.showNotInterested = true,
    this.network = true,
    this.cache = true,
    this.bodyMaxLines = 6,
    this.contentWrapper,
    this.onVideoTap,
    this.plainInlineStyles = false,
    this.enableTokenNavigation = false,
    super.key,
  });

  final EventReference eventReference;
  final EventReference? repostEventReference;
  final bool isAccentTheme;
  final bool displayQuote;
  final bool displayParent;
  final double? topOffset;
  final double? headerOffset;
  final Widget? header;
  final Widget? footer;
  final Widget? quotedEventFooter;
  final TimestampFormat timeFormat;
  final VoidCallback? onDelete;
  final bool isTextSelectable;
  final int? bodyMaxLines;
  final Widget Function(Widget content)? contentWrapper;
  final OnVideoTapCallback? onVideoTap;
  final bool showNotInterested;
  final bool network;
  final bool cache;
  final bool plainInlineStyles;
  final bool enableTokenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(
          ionConnectEntityWithCountersProvider(
            eventReference: eventReference,
            network: network,
            cache: cache,
          ).select((value) {
            final entity = value.valueOrNull;
            if (entity != null) {
              ListCachedObjects.updateObject<IonConnectEntity>(context, entity);
            }
            return entity;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<IonConnectEntity>(context, eventReference);

    if (entity == null) {
      return ScreenSideOffset.small(
        child: Skeleton(
          child: PostSkeleton(color: isAccentTheme ? Colors.white.withValues(alpha: 0.1) : null),
        ),
      );
    }

    if (entity is ModifiablePostEntity && entity.isDeleted) {
      return ScreenSideOffset.small(child: DeletedEntity(entityType: DeletedEntityType.post));
    }

    final quotedEventReference = _getQuotedEventReference(entity: entity);

    final parentEventReference = _getParentEventReference(entity: entity);

    final isParentShown = displayParent && parentEventReference != null;

    final hasToken = enableTokenNavigation &&
        (ref.watch(ionConnectEntityHasTokenProvider(eventReference: eventReference)).valueOrNull ??
            false);

    final content = Column(
      children: [
        SizedBox(height: headerOffset ?? 10.0.s),
        PostBody(
          entity: entity,
          maxLines: bodyMaxLines,
          onVideoTap: onVideoTap,
          accentTheme: isAccentTheme,
          isTextSelectable: isTextSelectable,
          framedEventReference: repostEventReference ?? quotedEventReference,
          plainInlineStyles: plainInlineStyles,
        ),
        if (displayQuote && quotedEventReference != null)
          ScreenSideOffset.small(
            child: _QuotedEvent(
              accentTheme: isAccentTheme,
              eventReference: quotedEventReference,
              footer: quotedEventFooter,
            ),
          ),
        footer ?? CounterItemsFooter(eventReference: eventReference),
      ],
    );

    final postWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isParentShown) ...[
          SizedBox(height: topOffset ?? 12.0.s),
          _ParentEvent(
            accentTheme: isAccentTheme,
            eventReference: parentEventReference,
            header: isAccentTheme && header != null ? header : null,
          ),
          SizedBox(height: 12.0.s),
        ],
        header ??
            UserInfo(
              pubkey: eventReference.masterPubkey,
              network: network,
              createdAt:
                  entity is ModifiablePostEntity ? entity.data.publishedAt.value : entity.createdAt,
              timeFormat: timeFormat,
              textStyle: isAccentTheme
                  ? context.theme.appTextThemes.caption.copyWith(
                      color: context.theme.appColors.onPrimaryAccent,
                    )
                  : null,
              trailing: ContentBottomSheetMenu(
                eventReference: eventReference,
                entity: entity,
                isAccentTheme: isAccentTheme,
                onDelete: onDelete,
                showNotInterested: showNotInterested,
              ),
              padding: EdgeInsetsDirectional.only(
                start: ScreenSideOffset.defaultSmallMargin,
                top: isParentShown ? 0 : (topOffset ?? 12.0.s),
              ),
            ),
        if (contentWrapper != null) contentWrapper!(content) else content,
      ],
    );

    if (hasToken) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            TokenizedCommunityRoute(externalAddress: eventReference.toString()).push<void>(context),
        child: postWidget,
      );
    }

    return postWidget;
  }

  EventReference? _getQuotedEventReference({required IonConnectEntity entity}) {
    return switch (entity) {
      ModifiablePostEntity() => entity.data.quotedEvent?.eventReference,
      PostEntity() => entity.data.quotedEvent?.eventReference,
      _ => null,
    };
  }

  EventReference? _getParentEventReference({required IonConnectEntity entity}) {
    return switch (entity) {
      ModifiablePostEntity() => entity.data.parentEvent?.eventReference,
      PostEntity() => entity.data.parentEvent?.eventReference,
      _ => null,
    };
  }
}

class _QuotedEvent extends StatelessWidget {
  const _QuotedEvent({
    required this.eventReference,
    this.accentTheme = false,
    this.footer,
  });

  final bool accentTheme;
  final EventReference eventReference;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(top: 12.0.s),
      child: _FramedEvent(
        eventReference: eventReference,
        postWidget: _QuotedPost(
          accentTheme: accentTheme,
          eventReference: eventReference,
        ),
        articleWidget: _QuotedArticle(
          accentTheme: accentTheme,
          eventReference: eventReference,
          footer: footer,
        ),
      ),
    );
  }
}

final class _ParentEvent extends StatelessWidget {
  const _ParentEvent({
    required this.eventReference,
    this.header,
    this.accentTheme = false,
  });

  final Widget? header;
  final bool accentTheme;
  final EventReference eventReference;

  @override
  Widget build(BuildContext context) {
    return _FramedEvent(
      eventReference: eventReference,
      isParent: true,
      postWidget: _ParentPost(
        header: header,
        accentTheme: accentTheme,
        eventReference: eventReference,
      ),
      articleWidget: _ParentArticle(
        header: header,
        accentTheme: accentTheme,
        eventReference: eventReference,
      ),
    );
  }
}

final class _FramedEvent extends HookConsumerWidget {
  const _FramedEvent({
    required this.eventReference,
    required this.postWidget,
    required this.articleWidget,
    this.isParent = false,
  });

  final EventReference eventReference;
  final Widget postWidget;
  final Widget articleWidget;
  final bool isParent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(
          ionConnectEntityWithCountersProvider(eventReference: eventReference).select((value) {
            final entity = value.valueOrNull;
            if (entity != null) {
              ListCachedObjects.updateObject<IonConnectEntity>(context, entity);
            }
            return entity;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<IonConnectEntity>(context, eventReference);

    Widget? deletedEntity;

    if (entity is ModifiablePostEntity && entity.isDeleted) {
      deletedEntity = Padding(
        padding: EdgeInsets.symmetric(horizontal: isParent ? 16.0.s : 0),
        child: DeletedEntity(
          entityType: DeletedEntityType.post,
          bottomPadding: isParent ? 4.0.s : 0,
          topPadding: 0,
        ),
      );
    }

    if (entity is ArticleEntity && entity.isDeleted) {
      deletedEntity = Padding(
        padding: EdgeInsets.symmetric(horizontal: isParent ? 16.0.s : 0),
        child: DeletedEntity(
          entityType: DeletedEntityType.article,
          bottomPadding: isParent ? 4.0.s : 0,
          topPadding: 0,
        ),
      );
    }

    if (deletedEntity != null && isParent) {
      deletedEntity = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          deletedEntity,
          ParentDottedLine(
            padding: EdgeInsetsDirectional.only(start: 32.0.s),
            child: SizedBox(height: 14.0.s),
          ),
          SizedBox(height: 4.0.s),
        ],
      );
    }

    // FIXME: we shouldn't memoize widgets
    final repliedEntity = useMemoized(
      () {
        switch (entity) {
          case ModifiablePostEntity() || PostEntity():
            return postWidget;
          case ArticleEntity():
            return articleWidget;
          case CommunityTokenDefinitionEntity():
            return CommunityTokenLiveBody(
              entity: entity,
              sidePadding: isParent ? null : 0,
            );
          case CommunityTokenActionEntity():
            return CommunityTokenActionBody(
              entity: entity,
              sidePadding: 0,
            );
          default:
            return const SizedBox.shrink();
        }
      },
      [entity],
    );

    return deletedEntity ?? repliedEntity;
  }
}

final class _QuotedPost extends ConsumerWidget {
  const _QuotedPost({
    required this.eventReference,
    this.accentTheme = false,
  });

  final bool accentTheme;
  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postEntity = ref.watch(
          ionConnectEntityWithCountersProvider(eventReference: eventReference).select((value) {
            final entity = value.valueOrNull;
            if (entity != null) {
              ListCachedObjects.updateObject<IonConnectEntity>(context, entity);
            }
            return entity;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<IonConnectEntity>(context, eventReference);

    return QuotedEntityFrame.post(
      child: GestureDetector(
        onTap: () {
          PostDetailsRoute(eventReference: eventReference.encode()).push<void>(context);
        },
        child: AbsorbPointer(
          child: Post(
            isAccentTheme: accentTheme,
            eventReference: eventReference,
            displayQuote: false,
            plainInlineStyles: true,
            header: UserInfo(
              network: true,
              accentTheme: accentTheme,
              pubkey: eventReference.masterPubkey,
              padding: EdgeInsetsDirectional.only(
                start: 16.0.s,
                top: 12.0.s,
              ),
              createdAt: postEntity is ModifiablePostEntity
                  ? postEntity.data.publishedAt.value
                  : postEntity?.createdAt,
            ),
            footer: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

final class _QuotedArticle extends StatelessWidget {
  const _QuotedArticle({
    required this.eventReference,
    this.accentTheme = false,
    this.footer,
  });

  final bool accentTheme;
  final EventReference eventReference;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return QuotedEntityFrame.article(
      child: GestureDetector(
        onTap: () {
          ArticleDetailsRoute(eventReference: eventReference.encode()).push<void>(context);
        },
        child: AbsorbPointer(
          child: Article.quoted(
            accentTheme: accentTheme,
            eventReference: eventReference,
            footer: footer,
          ),
        ),
      ),
    );
  }
}

final class _ParentPost extends StatelessWidget {
  const _ParentPost({
    required this.eventReference,
    this.header,
    this.accentTheme = false,
  });

  final Widget? header;
  final bool accentTheme;
  final EventReference eventReference;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        PostDetailsRoute(eventReference: eventReference.encode()).push<void>(context);
      },
      child: Post(
        topOffset: 0,
        header: header,
        headerOffset: 0,
        displayParent: true,
        isAccentTheme: accentTheme,
        eventReference: eventReference,
        contentWrapper: (content) {
          return ParentDottedLine(
            padding: EdgeInsetsDirectional.only(
              start: 31.0.s,
              top: 8.0.s,
              end: 8.0.s,
              bottom: 4.0.s,
            ),
            child: content,
          );
        },
      ),
    );
  }
}

final class _ParentArticle extends StatelessWidget {
  const _ParentArticle({
    required this.eventReference,
    this.header,
    this.accentTheme = false,
  });

  final Widget? header;
  final bool accentTheme;
  final EventReference eventReference;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ArticleDetailsRoute(eventReference: eventReference.encode()).push<void>(context);
      },
      child: AbsorbPointer(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0.s),
          child: Article.replied(
            header: header,
            accentTheme: accentTheme,
            eventReference: eventReference,
          ),
        ),
      ),
    );
  }
}
