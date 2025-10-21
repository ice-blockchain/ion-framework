// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/counter_items_footer/counter_items_footer.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/entities_list/components/bookmark_button/bookmark_button.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/components/parent_entity.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/components/article/components/article_footer/article_footer.dart';
import 'package:ion/app/features/feed/views/components/article/components/article_image/article_image.dart';
import 'package:ion/app/features/feed/views/components/deleted_entity/deleted_entity.dart';
import 'package:ion/app/features/feed/views/components/overlay_menu/own_entity_menu.dart';
import 'package:ion/app/features/feed/views/components/overlay_menu/user_info_menu.dart';
import 'package:ion/app/features/feed/views/components/post/post_skeleton.dart';
import 'package:ion/app/features/feed/views/components/time_ago/time_ago.dart';
import 'package:ion/app/features/feed/views/components/user_info/user_info.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/utils/algorithm.dart';
import 'package:ion/app/utils/color.dart';

class Article extends ConsumerWidget {
  const Article({
    required this.eventReference,
    this.header,
    this.footer,
    this.isReplied = false,
    this.accentTheme = false,
    this.addTrailingPadding = true,
    this.showActionButtons = true,
    this.showNotInterested = true,
    this.network = true,
    this.timeFormat = TimestampFormat.short,
    super.key,
  });

  factory Article.quoted({
    required EventReference eventReference,
    bool accentTheme = false,
    Widget? footer,
  }) {
    return Article(
      showActionButtons: false,
      addTrailingPadding: false,
      accentTheme: accentTheme,
      eventReference: eventReference,
      footer: footer,
    );
  }

  factory Article.replied({
    required EventReference eventReference,
    Widget? header,
    bool accentTheme = false,
  }) {
    return Article(
      header: header,
      isReplied: true,
      accentTheme: accentTheme,
      showActionButtons: false,
      eventReference: eventReference,
    );
  }

  final bool addTrailingPadding;
  final EventReference eventReference;
  final bool showActionButtons;
  final TimestampFormat timeFormat;
  final Widget? header;
  final bool isReplied;
  final Widget? footer;
  final bool accentTheme;
  final bool showNotInterested;
  final bool network;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(
          ionConnectEntityWithCountersProvider(eventReference: eventReference, network: network)
              .select((value) {
            final entity = value.valueOrNull;
            if (entity != null) {
              ListCachedObjects.updateObject<IonConnectEntity>(context, entity);
            }
            return entity;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<IonConnectEntity>(context, eventReference);

    if (entity is! ArticleEntity) {
      return Padding(
        padding: EdgeInsetsDirectional.only(start: 12.0.s),
        child: Skeleton(
          child: PostSkeleton(color: accentTheme ? Colors.white.withValues(alpha: 0.1) : null),
        ),
      );
    }

    if (entity.isDeleted) {
      return Padding(
        padding: EdgeInsetsDirectional.only(start: 16.0.s),
        child: DeletedEntity(entityType: DeletedEntityType.article),
      );
    }

    final isOwnedByCurrentUser = ref.watch(isCurrentUserSelectorProvider(entity.masterPubkey));

    return ColoredBox(
      color: accentTheme
          ? context.theme.appColors.primaryAccent
          : context.theme.appColors.onPrimaryAccent,
      child: Column(
        children: [
          if (isReplied && header != null)
            header!
          else if (isReplied) ...[
            UserInfo(
              pubkey: eventReference.masterPubkey,
              network: network,
              createdAt: entity.data.publishedAt.value,
              timeFormat: timeFormat,
              accentTheme: accentTheme,
              trailing: showActionButtons
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BookmarkButton(eventReference: eventReference),
                        if (isOwnedByCurrentUser)
                          OwnEntityMenu(eventReference: eventReference)
                        else
                          UserInfoMenu(
                            eventReference: eventReference,
                            showNotInterested: showNotInterested,
                          ),
                      ],
                    )
                  : null,
            ),
            SizedBox(height: 10.0.s),
          ],
          ParentDottedLine(
            visible: isReplied,
            padding: EdgeInsetsDirectional.only(
              start: 15.0.s,
              end: 22.0.s,
              bottom: 4.0.s,
            ),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        clipBehavior: Clip.antiAlias,
                        width: 4.0.s,
                        decoration: BoxDecoration(
                          color: entity.data.colorLabel != null
                              ? fromHexColor(entity.data.colorLabel!.values.first)
                              : context.theme.appColors.primaryAccent,
                          borderRadius: BorderRadiusDirectional.only(
                            topEnd: Radius.circular(4.0.s),
                            bottomEnd: Radius.circular(4.0.s),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.0.s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isReplied && header != null)
                              header!
                            else if (!isReplied) ...[
                              UserInfo(
                                pubkey: eventReference.masterPubkey,
                                createdAt: entity.data.publishedAt.value,
                                timeFormat: timeFormat,
                                accentTheme: accentTheme,
                                trailing: showActionButtons
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isOwnedByCurrentUser)
                                            OwnEntityMenu(eventReference: eventReference)
                                          else
                                            UserInfoMenu(
                                              eventReference: eventReference,
                                              showNotInterested: showNotInterested,
                                            ),
                                        ],
                                      )
                                    : null,
                              ),
                              SizedBox(height: 10.0.s),
                            ],
                            ArticleImage(
                              imageUrl: entity.data.image,
                              authorPubkey: eventReference.masterPubkey,
                              minutesToRead: calculateReadingTime(entity.data.content),
                            ),
                            SizedBox(height: 10.0.s),
                            ArticleFooter(
                              text: entity.data.title ?? '',
                              color: accentTheme
                                  ? context.theme.appColors.onPrimaryAccent
                                  : context.theme.appColors.sharkText,
                            ),
                          ],
                        ),
                      ),
                      if (addTrailingPadding) SizedBox(width: ScreenSideOffset.defaultSmallMargin),
                    ],
                  ),
                ),
                if (isReplied && showActionButtons)
                  footer ?? CounterItemsFooter(eventReference: eventReference, sidePadding: 0),
              ],
            ),
          ),
          if (!isReplied && showActionButtons)
            footer ?? CounterItemsFooter(eventReference: eventReference),
        ],
      ),
    );
  }
}
