// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/create_post/views/components/reply_input_field/reply_input_field.dart';
import 'package:ion/app/features/feed/data/models/analytics_events.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/providers/can_reply_notifier.r.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/components/community_token_action/community_token_action.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/community_token_live.dart';
import 'package:ion/app/features/feed/views/components/post/post.dart';
import 'package:ion/app/features/feed/views/components/reply_list/reply_list.dart';
import 'package:ion/app/features/feed/views/components/scroll_to_top_button/scroll_to_top_button.dart';
import 'package:ion/app/features/feed/views/components/time_ago/time_ago.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/services/analytics_service/analytics_service_provider.r.dart';

class PostDetailsPage extends HookConsumerWidget {
  const PostDetailsPage({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReply = ref.watch(canReplyProvider(eventReference)).value ?? false;
    final scrollController = useScrollController();
    final entity = ref
        .watch(
          ionConnectEntityWithCountersProvider(
            eventReference: eventReference,
          ),
        )
        .valueOrNull;
    final isReply = entity is ModifiablePostEntity && entity.data.isReply ||
        entity is PostEntity && entity.data.isReply;

    useOnInit(() {
      ref.read(analyticsServiceProvider).logEvent(PostViewAnalyticsEvent(eventReference));
    });

    return Scaffold(
      appBar: NavigationAppBar.screen(
        title: Text(context.i18n.post_page_title),
      ),
      body: ScrollToTopWrapper(
        scrollController: scrollController,
        child: Column(
          children: [
            Flexible(
              child: KeyboardDismissOnTap(
                child: Stack(
                  children: [
                    ReplyList(
                      eventReference: eventReference,
                      scrollController: scrollController,
                      isReply: isReply,
                      onPullToRefresh: () {
                        ref.read(ionConnectCacheProvider.notifier).remove(
                              CacheableEntity.cacheKeyBuilder(
                                eventReference: eventReference,
                              ),
                            );
                      },
                      headers: [
                        SliverToBoxAdapter(
                          child: switch (entity) {
                            CommunityTokenActionEntity() => _TokenNavigationWrapper(
                                entity: entity,
                                child: CommunityTokenAction(
                                  eventReference: eventReference,
                                ),
                              ),
                            CommunityTokenDefinitionEntity() => _TokenNavigationWrapper(
                                entity: entity,
                                child: CommunityTokenLive(
                                  eventReference: eventReference,
                                ),
                              ),
                            ModifiablePostEntity() || PostEntity() => _TokenNavigationWrapper(
                                eventReference: eventReference,
                                entity: entity,
                                child: Post(
                                  eventReference: eventReference,
                                  timeFormat: TimestampFormat.detailed,
                                  onDelete: context.pop,
                                  isTextSelectable: true,
                                  bodyMaxLines: null,
                                  displayParent: true,
                                  showNotInterested: false,
                                ),
                              ),
                            _ => const SizedBox.shrink(),
                          },
                        ),
                        const SliverToBoxAdapter(child: SectionSeparator()),
                      ],
                    ),
                    PositionedDirectional(
                      bottom: 12.5.s,
                      end: 16.0.s,
                      child: ScrollToTopButton(
                        scrollController: scrollController,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (canReply) ...[
              const HorizontalSeparator(),
              ReplyInputField(eventReference: eventReference),
            ],
          ],
        ),
      ),
    );
  }
}

class _TokenNavigationWrapper extends ConsumerWidget {
  const _TokenNavigationWrapper({
    required this.child,
    this.entity,
    this.eventReference,
  });

  final Widget child;
  final IonConnectEntity? entity;
  final EventReference? eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? externalAddress;

    switch (entity) {
      case final CommunityTokenDefinitionEntity tokenDef:
        externalAddress = tokenDef.data.externalAddress;
      case final CommunityTokenActionEntity tokenAction:
        final tokenDefinition = ref
            .watch(ionConnectEntityProvider(eventReference: tokenAction.data.definitionReference))
            .valueOrNull as CommunityTokenDefinitionEntity?;
        externalAddress = tokenDefinition?.data.externalAddress;
      case ModifiablePostEntity(data: ModifiablePostData(quotedEvent: final quotedEvent))
          when quotedEvent != null &&
              quotedEvent.eventReference.kind == CommunityTokenDefinitionEntity.kind:
        final quotedTokenDef = ref
            .watch(ionConnectEntityProvider(eventReference: quotedEvent.eventReference))
            .valueOrNull as CommunityTokenDefinitionEntity?;
        externalAddress = quotedTokenDef?.data.externalAddress;
      default:
        if (eventReference != null) {
          final hasToken = ref
                  .watch(ionConnectEntityHasTokenProvider(eventReference: eventReference!))
                  .valueOrNull ??
              false;
          externalAddress = hasToken ? eventReference.toString() : null;
        } else {
          externalAddress = null;
        }
    }

    if (externalAddress == null) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => TokenizedCommunityRoute(externalAddress: externalAddress!).push<void>(context),
      child: child,
    );
  }
}
