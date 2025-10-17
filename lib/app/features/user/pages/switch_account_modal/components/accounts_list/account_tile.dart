// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
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
    final eventSigner = ref.watch(currentUserIonConnectEventSignerProvider).valueOrNull;

    if (eventSigner == null) {
      return Skeleton(child: ListItem());
    }

    final userPreviewData = ref.watch(userPreviewDataProvider(eventSigner.publicKey)).valueOrNull;
    final isCurrentUser = identityKeyName == currentIdentityKeyName;

    if (userPreviewData == null) {
      return Skeleton(child: ListItem());
    }

    return BadgesUserListItem(
      isSelected: isCurrentUser,
      onTap: () {
        if (!isCurrentUser) {
          ref.read(authProvider.notifier).setCurrentUser(identityKeyName);
        }
      },
      title: Text(
        userPreviewData.data.trimmedDisplayName,
        strutStyle: const StrutStyle(forceStrutHeight: true),
      ),
      subtitle: Text(prefixUsername(username: userPreviewData.data.name, context: context)),
      masterPubkey: userPreviewData.masterPubkey,
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
