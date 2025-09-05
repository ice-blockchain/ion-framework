// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/views/components/chat_privacy_tooltip.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class SelectableUserListItem extends ConsumerWidget {
  const SelectableUserListItem({
    required this.pubkey,
    required this.masterPubkey,
    required this.onUserSelected,
    super.key,
    this.selectedPubkeys = const [],
    this.selectable = false,
    this.canSendMessage = true,
  });

  final String pubkey;
  final String masterPubkey;
  final void Function(UserMetadataEntity user) onUserSelected;
  final List<String> selectedPubkeys;
  final bool selectable;
  final bool canSendMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadataResult = ref.watch(userMetadataSyncProvider(masterPubkey, network: false));

    if (userMetadataResult == null) {
      return const SizedBox.shrink();
    }

    final isSelected = selectedPubkeys.contains(masterPubkey) || (selectedPubkeys.contains(pubkey));

    return ChatPrivacyTooltip(
      canSendMessage: canSendMessage,
      child: BadgesUserListItem(
        onTap: canSendMessage ? () => onUserSelected(userMetadataResult) : null,
        title: Text(userMetadataResult.data.displayName),
        subtitle: Text(prefixUsername(username: userMetadataResult.data.name, context: context)),
        pubkey: masterPubkey,
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
      ),
    );
  }
}
