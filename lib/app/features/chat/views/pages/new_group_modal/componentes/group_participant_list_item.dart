// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class GroupPariticipantsListItem extends ConsumerWidget {
  const GroupPariticipantsListItem({
    required this.onRemove,
    required this.participantMasterkey,
    required this.isCurrentUser,
    super.key,
  });

  final bool isCurrentUser;
  final VoidCallback onRemove;
  final String participantMasterkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadataResult = ref.watch(userMetadataProvider(participantMasterkey));

    return userMetadataResult.maybeWhen(
      data: (userMetadata) {
        if (userMetadata == null) return const SizedBox.shrink();

        return BadgesUserListItem(
          title: Text(userMetadata.data.trimmedDisplayName),
          subtitle: Text(
            prefixUsername(username: userMetadata.data.name, context: context),
            style: context.theme.appTextThemes.caption.copyWith(
              color: context.theme.appColors.sheetLine,
            ),
          ),
          masterPubkey: userMetadata.masterPubkey,
          contentPadding: EdgeInsets.zero,
          constraints: BoxConstraints(maxHeight: 39.0.s),
          trailing: isCurrentUser
              ? null
              : GestureDetector(
                  onTap: onRemove,
                  behavior: HitTestBehavior.opaque,
                  child: Assets.svg.iconBlockDelete.icon(
                    size: 24.0.s,
                    color: context.theme.appColors.sheetLine,
                  ),
                ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
