// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/views/components/chat_privacy_tooltip.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class SelectableUserListItem extends ConsumerWidget {
  const SelectableUserListItem({
    required this.userMetadata,
    required this.onUserSelected,
    super.key,
    this.selectable = false,
    this.canSendMessage = true,
    this.selectedPubkeys = const [],
  });

  final bool selectable;
  final bool canSendMessage;
  final List<String> selectedPubkeys;
  final UserMetadataEntity userMetadata;
  final void Function(UserMetadataEntity user) onUserSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterPubkey = userMetadata.pubkey;
    final isSelected = selectedPubkeys.contains(masterPubkey);

    return ChatPrivacyTooltip(
      canSendMessage: canSendMessage,
      child: BadgesUserListItem(
        leading: IonConnectAvatar(
          masterPubkey: masterPubkey,
          metadata: userMetadata,
          size: ListItem.defaultAvatarSize,
        ),
        masterPubkey: masterPubkey,
        title: Text(userMetadata.data.displayName),
        subtitle: Text(prefixUsername(username: userMetadata.data.name, context: context)),
        contentPadding: EdgeInsets.symmetric(
          vertical: 8.0.s,
          horizontal: ScreenSideOffset.defaultSmallMargin,
        ),
        trailing: selectable && canSendMessage
            ? isSelected
                ? Assets.svg.iconBlockCheckboxOnblue.icon(
                    color: context.theme.appColors.success,
                  )
                : Assets.svg.iconBlockCheckboxOff.icon(
                    color: context.theme.appColors.onTertiaryFill,
                  )
            : null,
        onTap: canSendMessage ? () => onUserSelected(userMetadata) : null,
      ),
    );
  }
}
