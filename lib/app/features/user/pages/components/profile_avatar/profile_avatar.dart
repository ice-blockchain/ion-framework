// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/story_colored_profile_avatar.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/avatar_picker/avatar_picker.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    required this.pubkey,
    this.showAvatarPicker = false,
    this.profileMode = ProfileMode.light,
    super.key,
  });

  static double get pictureSize => 65.0.s;

  static BorderRadiusGeometry get borderRadius => BorderRadius.circular(16.0.s);

  final String pubkey;
  final bool showAvatarPicker;
  final ProfileMode profileMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreviewData = ref
        .watch(userPreviewDataProvider(pubkey))
        .valueOrNull;

    return showAvatarPicker
        ? AvatarPicker(
      avatarUrl: userPreviewData?.data.avatarUrl,
      avatarSize: pictureSize,
      borderRadius: borderRadius,
      iconSize: 20.0.s,
      iconBackgroundSize: 30.0.s,
    )
        : StoryColoredProfileAvatar(
      pubkey: pubkey,
      size: pictureSize,
      borderRadius: borderRadius,
      fit: BoxFit.cover,
      imageUrl: userPreviewData?.data.avatarUrl,
      profileMode: profileMode,
    );
  }
}
