// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/avatar/default_avatar.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/providers/account_info_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class AccountsTile extends ConsumerWidget {
  const AccountsTile({
    required this.identityKeyName,
    super.key,
  });

  final String identityKeyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIdentityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
    final accountInfoAsync = ref.watch(accountInfoProvider(identityKeyName));
    final isCurrentUser = identityKeyName == currentIdentityKeyName;

    return accountInfoAsync.when(
      data: (AccountInfo? accountInfo) {
        if (accountInfo == null) {
          return _DefaultUserTile(
            identityKeyName: identityKeyName,
            isCurrentUser: isCurrentUser,
            onTap: () {
              if (!isCurrentUser) {
                unawaited(ref.read(authProvider.notifier).setCurrentUser(identityKeyName));
                if (context.mounted) {
                  context.maybePop();
                }
              }
            },
          );
        }

        return BadgesUserListItem(
          isSelected: isCurrentUser,
          onTap: () => ref.read(authProvider.notifier).setCurrentUser(identityKeyName),
          title: Text(
            accountInfo.userPreview.data.trimmedDisplayName,
            strutStyle: const StrutStyle(forceStrutHeight: true),
          ),
          subtitle: Text(
            prefixUsername(username: accountInfo.userPreview.data.name, context: context),
          ),
          masterPubkey: accountInfo.masterPubkey,
          trailing: isCurrentUser == true ? Assets.svg.iconBlockCheckboxOn.icon() : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0.s),
          backgroundColor: context.theme.appColors.tertiaryBackground,
          borderRadius: ListItem.defaultBorderRadius,
          constraints: ListItem.defaultConstraints,
        );
      },
      loading: () => Skeleton(child: ListItem()),
      error: (_, __) => Skeleton(child: ListItem()),
    );
  }
}

class _DefaultUserTile extends StatelessWidget {
  const _DefaultUserTile({
    required this.identityKeyName,
    required this.isCurrentUser,
    required this.onTap,
  });

  final String identityKeyName;
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
        identityKeyName,
        strutStyle: const StrutStyle(forceStrutHeight: true),
      ),
      trailing: isCurrentUser == true
          ? Assets.svg.iconBlockCheckboxOnblue.icon(color: context.theme.appColors.onPrimaryAccent)
          : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0.s),
      backgroundColor: context.theme.appColors.tertiaryBackground,
      borderRadius: ListItem.defaultBorderRadius,
      constraints: ListItem.defaultConstraints,
    );
  }
}
