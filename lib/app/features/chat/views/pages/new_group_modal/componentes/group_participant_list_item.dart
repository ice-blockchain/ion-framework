// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class GroupParticipantsListItem extends ConsumerWidget {
  const GroupParticipantsListItem({
    required this.participantMasterkey,
    this.role,
    this.onRemove,
    this.showRemoveButton = true,
    this.onTap,
    super.key,
  });

  final String participantMasterkey;
  final GroupMemberRole? role;
  final VoidCallback? onRemove;
  final bool showRemoveButton;
  final VoidCallback? onTap;

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
          onTap: onTap,
          trailing: role is GroupMemberRoleOwner
              ? const _OwnerBadge()
              : showRemoveButton
                  ? GestureDetector(
                      onTap: onRemove,
                      behavior: HitTestBehavior.opaque,
                      child: Assets.svg.iconBlockDelete.icon(
                        size: 24.0.s,
                        color: context.theme.appColors.sheetLine,
                      ),
                    )
                  : null,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _OwnerBadge extends StatelessWidget {
  const _OwnerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 2.0.s),
      decoration: ShapeDecoration(
        color: context.theme.appColors.primaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.s),
        ),
      ),
      child: Text(
        context.i18n.channel_create_admin_type_owner,
        style: context.theme.appTextThemes.caption3.copyWith(
          color: context.theme.appColors.primaryAccent,
        ),
      ),
    );
  }
}
