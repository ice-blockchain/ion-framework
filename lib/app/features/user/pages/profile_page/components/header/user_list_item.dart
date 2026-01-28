// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/story_colored_profile_avatar.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';

class UseListItem extends ConsumerWidget {
  const UseListItem({
    required this.masterPubkey,
    required this.minHeight,
    this.textColor,
    super.key,
  });

  final String masterPubkey;
  final double minHeight;
  final Color? textColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(masterPubkey).select(userPreviewDisplayNameSelector),
    );

    final textStyle = textColor != null ? TextStyle(color: textColor) : null;

    final username = ref.watch(
      userPreviewDataProvider(masterPubkey).select(userPreviewNameSelector),
    );

    return BadgesUserListItem(
      masterPubkey: masterPubkey,
      title: Text(
        displayName,
        strutStyle: const StrutStyle(forceStrutHeight: true),
        style: textStyle,
      ),
      subtitle: Text(
        prefixUsername(username: username, context: context),
        style: textStyle,
      ),
      leading: StoryColoredProfileAvatar(
        pubkey: masterPubkey,
        profileMode: ProfileMode.dark,
        size: ListItem.defaultAvatarSize,
      ),
      constraints: BoxConstraints(maxHeight: minHeight, minHeight: minHeight),
    );
  }
}
