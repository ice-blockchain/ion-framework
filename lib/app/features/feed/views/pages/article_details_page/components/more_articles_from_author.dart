// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/providers/user_articles_data_source_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/article_details_section_header.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/components/articles_carousel.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class MoreArticlesFromAuthor extends ConsumerWidget {
  const MoreArticlesFromAuthor({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSource = ref.watch(userArticlesDataSourceProvider(eventReference.masterPubkey));
    final entitiesPagedData = ref.watch(entitiesPagedDataProvider(dataSource));

    final articlesReferences = entitiesPagedData?.data.items
        ?.whereType<ArticleEntity>()
        .where((article) => article.toEventReference() != eventReference)
        .map((article) => article.toEventReference())
        .toList();

    final authorDisplayName = ref.watch(
      userPreviewDataProvider(eventReference.masterPubkey).select(userPreviewDisplayNameSelector),
    );

    if (articlesReferences == null || articlesReferences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(height: 20.0.s),
        ScreenSideOffset.small(
          child: ArticleDetailsSectionHeader(
            title: context.i18n.article_page_from_author(authorDisplayName),
            count: articlesReferences.length,
            trailing: GestureDetector(
              onTap: () =>
                  ArticlesFromAuthorRoute(pubkey: eventReference.masterPubkey).push<void>(context),
              child: Assets.svg.iconButtonNext.icon(),
            ),
          ),
        ),
        SizedBox(height: 16.0.s),
        ArticlesCarousel(articlesReferences: articlesReferences),
      ],
    );
  }
}
