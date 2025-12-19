// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/components/bottom_sheet_menu/content_bottom_sheet_menu.dart';
import 'package:ion/app/features/feed/views/components/feed_network_image/feed_network_image.dart';
import 'package:ion/app/features/feed/views/components/user_info/user_info.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class ArticlesCarouselItem extends ConsumerWidget {
  const ArticlesCarouselItem({required this.eventReference, super.key});

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article =
        ref.watch(ionConnectSyncEntityWithCountersProvider(eventReference: eventReference));

    if (article is! ArticleEntity || article.isDeleted) {
      return const SizedBox.shrink();
    }

    final topics = article.data.topics;
    final availableSubcategories = ref.watch(
      feedUserInterestsProvider(FeedType.article)
          .select((state) => state.valueOrNull?.subcategories ?? {}),
    );
    final topicsNames = topics.map((key) => availableSubcategories[key]?.display).nonNulls.toList();

    return GestureDetector(
      onTap: () => ArticleDetailsRoute(eventReference: eventReference.encode()).push<void>(context),
      child: Column(
        children: [
          UserInfo(
            pubkey: article.masterPubkey,
            trailing: ContentBottomSheetMenu(
              eventReference: eventReference,
              entity: article,
            ),
          ),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (topics.isNotEmpty && topicsNames.isNotEmpty) ...[
                        SizedBox(height: 10.0.s),
                        Text(
                          context.i18n.article_page_in_topic(topicsNames.first),
                          style: context.theme.appTextThemes.caption2.copyWith(
                            color: context.theme.appColors.tertiaryText,
                          ),
                          maxLines: 2,
                        ),
                      ],
                      SizedBox(height: 10.0.s),
                      Padding(
                        padding: EdgeInsetsDirectional.only(end: 12.0.s),
                        child: Text(
                          article.data.title ?? '',
                          maxLines: 3,
                          style: context.theme.appTextThemes.subtitle3.copyWith(
                            color: context.theme.appColors.sharkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 4.0.s),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0.s),
                    child: SizedBox(
                      width: 96.0.s,
                      height: 87.0.s,
                      child: article.data.image != null
                          ? FeedIONConnectNetworkImage(
                              imageUrl: article.data.image!,
                              authorPubkey: article.masterPubkey,
                              fit: BoxFit.cover,
                            )
                          : const ColoredBox(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
