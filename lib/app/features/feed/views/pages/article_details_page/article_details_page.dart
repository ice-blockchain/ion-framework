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
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/providers/parsed_media_provider.r.dart';
import 'package:ion/app/features/feed/views/components/bottom_sheet_menu/content_bottom_sheet_menu.dart';
import 'package:ion/app/features/feed/views/components/deleted_entity/deleted_entity.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/article_content_measurer.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/article_details_date_topics.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/article_details_header.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/article_details_progress_indicator.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/article_details_topics.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/more_articles_from_author.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/more_articles_from_topic.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/user_biography.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/hooks/use_article_content_height.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/hooks/use_scroll_indicator.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';

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

    if (articleEntity is! ArticleEntity) {
      return const SizedBox.shrink();
    }

    final scrollController = useScrollController();
    final screenWidth = MediaQuery.sizeOf(context).width;

    final (:content, :media) =
        ListCachedObjects.maybeObjectOf<MediaContentWithKey>(context, articleEntity.id)
                ?.mediaWithContent ??
            ref.watch(
              parsedMediaWithMentionsProvider(articleEntity.data).select((value) {
                ListCachedObjects.updateObject(
                  context,
                  (key: articleEntity.id, mediaWithContent: value),
                );
                return (content: value.content, media: value.media);
              }),
            );

    final mediaMap = {
      ...articleEntity.data.media,
      for (final entry in articleEntity.data.media.entries) entry.value.url: entry.value,
    };

    final topics = articleEntity.data.topics;
    final availableSubcategories = ref.watch(
      feedUserInterestsProvider(FeedType.article)
          .select((state) => state.valueOrNull?.subcategories ?? {}),
    );
    final topicsNames = topics.map((key) => availableSubcategories[key]?.display).nonNulls.toList();

    if (articleEntity.isDeleted) {
      DeletedEntity(entityType: DeletedEntityType.article);
    }

    List<Widget> buildContentItems({bool forMeasurement = false}) {
      return [
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
            child: forMeasurement
                ? ArticleContentMeasurer(
                    content: content,
                    media: mediaMap,
                  )
                : TextEditorPreview(
                    content: content,
                    media: mediaMap,
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
      ];
    }

    // Measure the full content height offscreen
    final (contentHeight, contentMeasurer) = useContentHeight(
      contentKey: content,
      contentBuilder: (key) => SizedBox(
        key: key,
        width: screenWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buildContentItems(forMeasurement: true),
        ),
      ),
    );

    final progress = useScrollIndicator(
      scrollController,
      totalContentHeight: contentHeight,
    );

    return Scaffold(
      appBar: NavigationAppBar.screen(
        actions: [
          ContentBottomSheetMenu.forAppBar(
            eventReference: eventReference,
            entity: articleEntity,
            onDelete: context.pop,
            iconColor: context.theme.appColors.onTertiaryBackground,
            showShadow: false,
          ),
        ],
      ),
      body: Stack(
        children: [
          Offstage(
            child: OverflowBox(
              alignment: AlignmentDirectional.topStart,
              maxHeight: double.infinity,
              child: contentMeasurer,
            ),
          ),
          ScrollToTopWrapper(
            scrollController: scrollController,
            child: Column(
              children: [
                ArticleDetailsProgressIndicator(progress: progress),
                Flexible(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverList(
                        delegate: SliverChildListDelegate(buildContentItems()),
                      ),
                    ],
                  ),
                ),
                const HorizontalSeparator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
