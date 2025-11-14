// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/providers/main_wallet_for_account_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class AccountsTile extends ConsumerWidget {
  const AccountsTile({
    required this.identityKeyName,
    super.key,
  });

  final String identityKeyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIdentityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
    final mainWalletAsync = ref.watch(mainWalletForAccountProvider(identityKeyName));
    final isCurrentUser = identityKeyName == currentIdentityKeyName;

    return mainWalletAsync.when(
      data: (Wallet? mainWallet) {
        if (mainWallet == null) {
          return Skeleton(child: ListItem());
        }

        final masterPubkey = mainWallet.signingKey.publicKey;
        final userPreviewData = ref.watch(userPreviewDataProvider(masterPubkey)).valueOrNull;

        if (userPreviewData == null) {
          return Skeleton(child: ListItem());
        }

        return BadgesUserListItem(
          isSelected: isCurrentUser,
          onTap: () {
            if (!isCurrentUser) {
              unawaited(ref.read(authProvider.notifier).setCurrentUser(identityKeyName));
              if (context.mounted) {
                context.maybePop();
              }
            }
          },
          title: Text(
            userPreviewData.data.trimmedDisplayName,
            strutStyle: const StrutStyle(forceStrutHeight: true),
          ),
          subtitle: Text(prefixUsername(username: userPreviewData.data.name, context: context)),
          masterPubkey: userPreviewData.masterPubkey,
          trailing: isCurrentUser == true
              ? Assets.svg.iconBlockCheckboxOnblue
                  .icon(color: context.theme.appColors.onPrimaryAccent)
              : null,
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
