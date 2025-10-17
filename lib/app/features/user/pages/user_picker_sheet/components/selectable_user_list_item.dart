// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/views/components/chat_privacy_tooltip.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class SelectableUserListItem extends ConsumerWidget {
  const SelectableUserListItem({
    required this.masterPubkey,
    required this.onUserSelected,
    super.key,
    this.selectable = false,
    this.canSendMessage = true,
    this.selectedPubkeys = const [],
  });

  final bool selectable;
  final bool canSendMessage;
  final List<String> selectedPubkeys;
  final String masterPubkey;
  final void Function(String masterPubkey) onUserSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName =
        ref.watch(userPreviewDataProvider(masterPubkey).select(userPreviewDisplayNameSelector));

    final username =
        ref.watch(userPreviewDataProvider(masterPubkey).select(userPreviewNameSelector));

    final isSelected = selectedPubkeys.contains(masterPubkey);

    return ChatPrivacyTooltip(
      canSendMessage: canSendMessage,
      child: BadgesUserListItem(
        masterPubkey: masterPubkey,
        title: Text(displayName, strutStyle: const StrutStyle(forceStrutHeight: true)),
        subtitle: Text(prefixUsername(username: username, context: context)),
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
        onTap: canSendMessage ? () => onUserSelected(masterPubkey) : null,
      ),
    );
  }
}
