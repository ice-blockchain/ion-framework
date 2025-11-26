// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/core/story_overlay_content_visibility_wrapper.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/header/header.dart';
import 'package:ion/app/features/feed/views/components/time_ago/time_ago.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';

class StoryViewerHeader extends ConsumerWidget {
  const StoryViewerHeader({
    required this.currentPost,
    super.key,
  });

  final ModifiablePostEntity currentPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(currentPost.masterPubkey).select(userPreviewDisplayNameSelector),
    );

    final username = ref.watch(
      userPreviewDataProvider(currentPost.masterPubkey).select(userPreviewNameSelector),
    );

    final appColors = context.theme.appColors;
    final textThemes = context.theme.appTextThemes;
    final onPrimaryAccent = appColors.onPrimaryAccent;
    final primaryTextWithAlpha = appColors.primaryText.withValues(alpha: 0.25);

    final shadow = [
      Shadow(
        offset: Offset(
          0.0.s,
          0.3.s,
        ),
        blurRadius: 1,
        color: primaryTextWithAlpha,
      ),
    ];

    return PositionedDirectional(
      top: 8.0.s,
      start: 16.0.s,
      end: 16.0.s,
      child: StoryOverlayContentVisibilityWrapper(
        child: GestureDetector(
          onTap: () => ProfileRoute(pubkey: currentPost.masterPubkey).push<void>(context),
          child: BadgesUserListItem(
            masterPubkey: currentPost.masterPubkey,
            leading: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.s),
                boxShadow: [
                  BoxShadow(
                    offset: shadow.first.offset,
                    blurRadius: shadow.first.blurRadius,
                    color: shadow.first.color,
                  ),
                ],
              ),
              child: IonConnectAvatar(
                size: ListItem.defaultAvatarSize,
                masterPubkey: currentPost.masterPubkey,
              ),
            ),
            title: Text(
              displayName,
              style: textThemes.subtitle3.copyWith(
                color: onPrimaryAccent,
                shadows: shadow,
              ),
              strutStyle: const StrutStyle(forceStrutHeight: true),
            ),
            subtitle: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prefixUsername(username: username, context: context),
                  style: textThemes.caption.copyWith(
                    color: onPrimaryAccent,
                    shadows: shadow,
                  ),
                ),
                if (!currentPost.isDeleted) ...[
                  SizedBox(width: 4.0.s),
                  Text(
                    '•',
                    style: textThemes.caption.copyWith(
                      color: onPrimaryAccent,
                      shadows: shadow,
                    ),
                  ),
                  SizedBox(width: 4.0.s),
                  TimeAgo(
                    time: currentPost.data.publishedAt.value.toDateTime,
                    style: textThemes.caption.copyWith(
                      color: onPrimaryAccent,
                      shadows: shadow,
                    ),
                  ),
                ],
              ],
            ),
            trailing: HeaderActions(post: currentPost),
            backgroundColor: context.theme.appColors.postContent.withValues(alpha: 0.50),
            contentPadding: EdgeInsetsDirectional.symmetric(horizontal: 12.0.s, vertical: 9.0.s),
            borderRadius: BorderRadius.all(Radius.circular(20.0.s)),
            constraints: BoxConstraints(minHeight: 30.0.s),
          ),
        ),
      ),
    );
  }
}
