// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/avatar/default_avatar.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/providers/switch_account_modal_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class SwitchAccountModalTile extends HookConsumerWidget {
  const SwitchAccountModalTile({
    required this.identityKeyName,
    required this.isCurrentUser,
    required this.onSelectUser,
    this.currentPubkey,
    super.key,
  });

  final String identityKeyName;
  final bool isCurrentUser;
  final VoidCallback onSelectUser;
  final String? currentPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = currentPubkey == null
        ? ref.watch(switchAccountModalUserDetailsProvider(identityKeyName)).valueOrNull
        : null;

    final masterPubkey = currentPubkey ?? details?.masterPubKey;

    final userPreview =
        masterPubkey != null ? ref.watch(userPreviewDataProvider(masterPubkey)).valueOrNull : null;

    if (masterPubkey == null || userPreview == null) {
      return _DefaultUserTile(
        username: identityKeyName,
        isCurrentUser: isCurrentUser,
        onTap: () => _handleTap(ref),
      );
    }

    return BadgesUserListItem(
      isSelected: isCurrentUser,
      onTap: () => _handleTap(ref),
      titleSpan: TextSpan(text: userPreview.data.trimmedDisplayName),
      subtitle: Text(
        withPrefix(
          input: userPreview.data.name,
          textDirection: Directionality.of(context),
        ),
      ),
      masterPubkey: masterPubkey,
      trailing: isCurrentUser ? Assets.svg.iconBlockCheckboxOn.icon() : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0.s),
      backgroundColor: context.theme.appColors.tertiaryBackground,
      borderRadius: ListItem.defaultBorderRadius,
      constraints: ListItem.defaultConstraints,
    );
  }

  Future<void> _handleTap(WidgetRef ref) async {
    if (!isCurrentUser) {
      await ref.read(switchAccountModalNotifierProvider.notifier).setCurrentUser(identityKeyName);
      await ref.read(authProvider.future);
      onSelectUser();
    }
  }
}

class _DefaultUserTile extends StatelessWidget {
  const _DefaultUserTile({
    required this.username,
    required this.isCurrentUser,
    required this.onTap,
  });

  final String username;
  final bool isCurrentUser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListItem(
      leading: Avatar(
        imageWidget: DefaultAvatar(size: ListItem.defaultAvatarSize),
        size: ListItem.defaultAvatarSize,
        borderRadius: BorderRadius.circular(8.0.s),
        fit: BoxFit.fitWidth,
      ),
      onTap: onTap,
      title: Text(
        username,
        strutStyle: const StrutStyle(forceStrutHeight: true),
      ),
      trailing: isCurrentUser
          ? Assets.svg.iconBlockCheckboxOnblue.icon(color: context.theme.appColors.onPrimaryAccent)
          : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0.s),
      backgroundColor: context.theme.appColors.tertiaryBackground,
      borderRadius: ListItem.defaultBorderRadius,
      constraints: ListItem.defaultConstraints,
    );
  }
}
