// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/follow_button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/mute_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/views/components/user_info/user_info.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_provider.r.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/video/views/components/video_button.dart';
import 'package:ion/app/features/video/views/components/video_post_text.dart';
import 'package:ion/generated/assets.gen.dart';

class VideoPostInfo extends StatelessWidget {
  const VideoPostInfo({
    required this.videoPost,
    super.key,
  });

  final IonConnectEntity videoPost;

  static final shadow = BoxShadow(
    offset: Offset(0, 1.5.s),
    blurRadius: 1.5.s,
    color: Colors.black.withValues(alpha: 0.4),
  );

  @override
  Widget build(BuildContext context) {
    final publishedAt = switch (videoPost) {
      final ModifiablePostEntity post => post.data.publishedAt.value,
      _ => videoPost.createdAt,
    };

    final followButton = Consumer(
      builder: (context, ref, child) {
        return FollowButton(
          visibility: FollowButtonVisibility.keepUntilRefresh,
          onPressed: () async {
            await ref.read(toggleFollowNotifierProvider.notifier).toggle(videoPost.masterPubkey);
          },
          following: ref.watch(isCurrentUserFollowingSelectorProvider(videoPost.masterPubkey)),
        );
      },
    );

    final muteButton = Consumer(
      builder: (context, ref, child) {
        final isMuted = ref.watch(globalMuteNotifierProvider);
        return VideoButton(
          icon: (isMuted ? Assets.svg.iconChannelMute : Assets.svg.iconChannelUnmute).icon(
            color: context.theme.appColors.secondaryBackground,
            size: 20.0.s,
          ),
          borderRadius: BorderRadius.circular(16.0.s),
          onPressed: () async {
            await ref.read(globalMuteNotifierProvider.notifier).toggle();
          },
        );
      },
    );

    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        followButton,
        SizedBox(width: 8.0.s),
        muteButton,
      ],
    );

    return Column(
      children: [
        Container(
          padding: EdgeInsetsDirectional.only(top: 6.0.s, start: 16.0.s, end: 16.0.s),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.5497, 1.0],
              colors: [
                context.theme.appColors.primaryText.withValues(alpha: 0),
                context.theme.appColors.primaryText.withValues(alpha: 0.3),
                context.theme.appColors.primaryText.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              UserInfo(
                pubkey: videoPost.masterPubkey,
                createdAt: publishedAt,
                shadow: shadow,
                textStyle: TextStyle(
                  color: context.theme.appColors.secondaryBackground,
                  shadows: [shadow],
                ),
                trailing: trailing,
                accentTheme: true,
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  bottom: 14.0.s,
                ),
                child: VideoTextPost(entity: videoPost),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
