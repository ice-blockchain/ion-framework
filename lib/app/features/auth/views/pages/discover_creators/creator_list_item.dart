// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/follow_button.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/utils/username.dart';

class CreatorListItem extends ConsumerWidget {
  const CreatorListItem({
    required this.userMetadataEntity,
    required this.onPressed,
    required this.selected,
    super.key,
  });

  final UserMetadataEntity userMetadataEntity;

  final VoidCallback onPressed;

  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenSideOffset.small(
      child: BadgesUserListItem(
        title: Text(userMetadataEntity.data.trimmedDisplayName),
        subtitle: Text(prefixUsername(username: userMetadataEntity.data.name, context: context)),
        masterPubkey: userMetadataEntity.masterPubkey,
        backgroundColor: context.theme.appColors.tertiaryBackground,
        contentPadding: EdgeInsets.all(12.0.s),
        borderRadius: BorderRadius.circular(16.0.s),
        trailing: FollowButton(onPressed: onPressed, following: selected),
        trailingPadding: EdgeInsetsDirectional.only(start: 6.0.s),
      ),
    );
  }
}
