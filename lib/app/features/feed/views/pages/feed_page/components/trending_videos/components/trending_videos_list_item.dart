// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/placeholder/ion_placeholder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/views/components/feed_network_image/feed_network_image.dart';
import 'package:ion/app/features/feed/views/components/overlay_menu/own_entity_menu.dart';
import 'package:ion/app/features/feed/views/components/overlay_menu/user_info_menu.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/trending_videos/components/trending_video_author.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/trending_videos/components/trending_video_likes_button.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/user/providers/muted_users_notifier.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class TrendingVideoListItem extends ConsumerWidget {
  const TrendingVideoListItem({
    required this.video,
    required this.itemSize,
    super.key,
  });

  final ModifiablePostEntity video;
  final Size itemSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isBlockedOrMutedOrBlocking(ref, video)) {
      return const SizedBox.shrink();
    }

    final eventReference = video.toEventReference();

    final thumbnailUrl = video.data.primaryVideo?.thumb;
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
      return _PlaceholderThumbnail(size: itemSize);
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(end: 12.0.s),
      child: GestureDetector(
        onTap: () {
          TrendingVideosRoute(
            eventReference: eventReference.encode(),
          ).push<void>(context);
        },
        child: _VideoContainer(
          thumbnailUrl: thumbnailUrl,
          size: itemSize,
          eventReference: eventReference,
        ),
      ),
    );
  }

  bool _isBlockedOrMutedOrBlocking(WidgetRef ref, IonConnectEntity entity) {
    final isMuted = ref.watch(isUserMutedProvider(entity.masterPubkey));
    final isBlockedOrBlockedBy = ref.watch(isEntityBlockedOrBlockedByProvider(entity));
    return isMuted || isBlockedOrBlockedBy;
  }
}

class _PlaceholderThumbnail extends StatelessWidget {
  const _PlaceholderThumbnail({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 12.0.s),
      child: Container(
        width: size.width,
        height: size.height,
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0.s),
        ),
        child: const Center(
          child: IonPlaceholder(),
        ),
      ),
    );
  }
}

class _VideoContainer extends StatelessWidget {
  const _VideoContainer({
    required this.thumbnailUrl,
    required this.size,
    required this.eventReference,
  });

  final String thumbnailUrl;
  final Size size;
  final EventReference eventReference;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0.s),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FeedIONConnectNetworkImage(
              imageUrl: thumbnailUrl,
              authorPubkey: eventReference.masterPubkey,
              fit: BoxFit.cover,
              height: size.height,
              width: size.width,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TopControls(eventReference: eventReference),
                TrendingVideoAuthor(pubkey: eventReference.masterPubkey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopControls extends ConsumerWidget {
  const _TopControls({required this.eventReference});

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwnedByCurrentUser =
        ref.watch(isCurrentUserSelectorProvider(eventReference.masterPubkey));
    final menuPadding = EdgeInsetsDirectional.only(start: 6.0.s, end: 6.0.s, top: 12.0.s);

    return SizedBox(
      height: 40.0.s,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TrendingVideoLikesButton(eventReference: eventReference),
          if (isOwnedByCurrentUser)
            OwnEntityMenu(
              showShadow: true,
              iconSize: 16.0.s,
              eventReference: eventReference,
              iconColor: context.theme.appColors.onPrimaryAccent,
              padding: menuPadding,
              onDelete: context.canPop,
            )
          else
            UserInfoMenu(
              showShadow: true,
              iconSize: 16.0.s,
              eventReference: eventReference,
              iconColor: context.theme.appColors.onPrimaryAccent,
              padding: menuPadding,
            ),
        ],
      ),
    );
  }
}
