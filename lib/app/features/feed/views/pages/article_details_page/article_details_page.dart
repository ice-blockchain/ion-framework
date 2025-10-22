// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/counter_items_footer/counter_items_footer.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/components/text_editor/text_editor_preview.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/components/deleted_entity/deleted_entity.dart';
import 'package:ion/app/features/feed/views/components/overlay_menu/own_entity_menu.dart';
import 'package:ion/app/features/feed/views/components/overlay_menu/user_info_menu.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/article_details_date_topics.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/article_details_header.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/article_details_progress_indicator.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/article_details_topics.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/more_articles_from_author.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/more_articles_from_topic.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/user_biography.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/hooks/use_scroll_indicator.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/services/markdown/quill.dart';

class ArticleDetailsPage extends HookConsumerWidget {
  const ArticleDetailsPage({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleEntity =
        ref.watch(ionConnectSyncEntityWithCountersProvider(eventReference: eventReference));
    final isOwnedByCurrentUser =
        ref.watch(isCurrentUserSelectorProvider(eventReference.masterPubkey));

    if (articleEntity is! ArticleEntity) {
      return const SizedBox.shrink();
    }

    final scrollController = useScrollController();
    final progress = useScrollIndicator(scrollController);

    final delta = useMemoized(
      () => parseAndConvertDelta(
        articleEntity.data.richText?.content,
        articleEntity.data.content,
      ),
      [articleEntity.data.richText?.content, articleEntity.data.content],
    );

    final topics = articleEntity.data.topics;
    final availableSubcategories = ref.watch(
      feedUserInterestsProvider(FeedType.article)
          .select((state) => state.valueOrNull?.subcategories ?? {}),
    );
    final topicsNames = topics.map((key) => availableSubcategories[key]?.display).nonNulls.toList();

    if (articleEntity.isDeleted) {
      DeletedEntity(entityType: DeletedEntityType.article);
    }

    return Scaffold(
      appBar: NavigationAppBar.screen(
        actions: [
          if (isOwnedByCurrentUser)
            OwnEntityMenu(eventReference: eventReference, onDelete: context.pop)
          else
            UserInfoMenu(
              eventReference: eventReference,
              showNotInterested: false,
            ),
        ],
      ),
      body: ScrollToTopWrapper(
        scrollController: scrollController,
        child: Column(
          children: [
            ArticleDetailsProgressIndicator(progress: progress),
            Flexible(
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      SizedBox(height: 13.0.s),
                      ScreenSideOffset.small(
                        child: ArticleDetailsDateTopics(
                          publishedAt: articleEntity.data.publishedAt.value.toDateTime,
                          topicsNames: topicsNames,
                        ),
                      ),
                      SizedBox(height: 16.0.s),
                      if (articleEntity.isDeleted)
                        ScreenSideOffset.small(
                          child: DeletedEntity(entityType: DeletedEntityType.article),
                        )
                      else ...[
                        ArticleDetailsHeader(
                          article: articleEntity,
                        ),
                        if (articleEntity.data.content.isNotEmpty) SizedBox(height: 20.0.s),
                        ScreenSideOffset.small(
                          child: TextEditorPreview(
                            content: delta,
                            media: articleEntity.data.media,
                            authorPubkey: articleEntity.masterPubkey,
                            enableInteractiveSelection: true,
                            eventReference: eventReference.encode(),
                          ),
                        ),
                      ],
                      CounterItemsFooter(eventReference: eventReference),
                      const SectionSeparator(),
                      SizedBox(height: 20.0.s),
                      ScreenSideOffset.small(
                        child: UserBiography(eventReference: eventReference),
                      ),
                      if (topicsNames.isNotEmpty) ...[
                        SizedBox(height: 20.0.s),
                        ArticleDetailsTopics(topics: topicsNames),
                      ],
                      MoreArticlesFromAuthor(eventReference: eventReference),
                      if (topics.isNotEmpty && topicsNames.isNotEmpty)
                        MoreArticlesFromTopic(
                          eventReference: eventReference,
                          topicKey: topics.first,
                          topicName: topicsNames.first,
                        ),
                      ScreenBottomOffset(),
                    ]),
                  ),
                ],
              ),
            ),
            const HorizontalSeparator(),
          ],
        ),
      ),
    );
  }
}
