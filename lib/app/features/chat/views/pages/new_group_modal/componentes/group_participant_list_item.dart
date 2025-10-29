// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class GroupParticipantsListItem extends ConsumerWidget {
  const GroupParticipantsListItem({
    required this.onRemove,
    required this.participantMasterkey,
    super.key,
  });

  final VoidCallback onRemove;
  final String participantMasterkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreviewResult = ref.watch(userPreviewDataProvider(participantMasterkey));

    return userPreviewResult.maybeWhen(
      data: (userPreviewData) {
        if (userPreviewData == null) return const SizedBox.shrink();

        return BadgesUserListItem(
          title: Text(userPreviewData.data.trimmedDisplayName),
          subtitle: Text(
            prefixUsername(username: userPreviewData.data.name, context: context),
            style: context.theme.appTextThemes.caption.copyWith(
              color: context.theme.appColors.sheetLine,
            ),
          ),
          masterPubkey: userPreviewData.masterPubkey,
          contentPadding: EdgeInsets.zero,
          constraints: BoxConstraints(maxHeight: 39.0.s),
          trailing: GestureDetector(
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
