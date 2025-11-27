// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/story_colored_profile_avatar.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/avatar_picker/avatar_picker.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    required this.pubkey,
    this.showAvatarPicker = false,
    this.profileMode = ProfileMode.light,
    this.size,
    super.key,
  });

  static BorderRadiusGeometry get borderRadius => BorderRadius.circular(16.0.s);

  final String pubkey;
  final bool showAvatarPicker;
  final ProfileMode profileMode;
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreviewData = ref.watch(userPreviewDataProvider(pubkey)).valueOrNull;
    final avatarUrl = userPreviewData?.data.avatarUrl;

    final pictureSize = size ?? 65.0.s;

    return showAvatarPicker
        ? AvatarPicker(
            avatarUrl: avatarUrl,
            avatarSize: pictureSize,
            borderRadius: borderRadius,
            iconSize: 20.0.s,
            iconBackgroundSize: 30.0.s,
          )
        : GestureDetector(
            onTap: avatarUrl == null
                ? null
                : () => AvatarOverlayRoute(pubkey: pubkey).push<void>(context),
            child: StoryColoredProfileAvatar(
              pubkey: pubkey,
              size: pictureSize,
              borderRadius: borderRadius,
              fit: BoxFit.cover,
              imageUrl: avatarUrl,
              profileMode: profileMode,
            ),
          );
  }
}
