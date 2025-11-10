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
    this.onActionTap,
    this.onTap,
    this.actionType,
    this.disabled = false,
    super.key,
  });

  final String participantMasterkey;
  final GroupMemberRole? role;
  final VoidCallback? onActionTap;
  final VoidCallback? onTap;
  final ActionType? actionType;
  final bool disabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreviewResult = ref.watch(userPreviewDataProvider(participantMasterkey));

    return userPreviewResult.maybeWhen(
      data: (userPreviewData) {
        if (userPreviewData == null) return const SizedBox.shrink();

        Widget? trailing;
        if (role is GroupMemberRoleOwner ||
            role is GroupMemberRoleAdmin ||
            role is GroupMemberRoleModerator) {
          trailing = _RoleBadge(role: role!);
        } else if (actionType == ActionType.select) {
          trailing = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Assets.svg.iconArrowRight.icon(
                size: 24.0.s,
                color: context.theme.appColors.tertiaryText,
              ),
            ],
          );
        }

        final item = BadgesUserListItem(
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
          onTap: disabled ? null : onTap,
          trailing: trailing,
        );

        return disabled
            ? Opacity(
                opacity: 0.5,
                child: item,
              )
            : item;
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({
    required this.role,
  });

  final GroupMemberRole role;

  @override
  Widget build(BuildContext context) {
    final roleText = switch (role) {
      GroupMemberRoleOwner() => context.i18n.channel_create_admin_type_owner,
      GroupMemberRoleAdmin() => context.i18n.channel_create_admin_type_admin,
      GroupMemberRoleModerator() => context.i18n.channel_create_admin_type_moderator,
      GroupMemberRoleMember() => '',
    };

    if (roleText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 2.0.s),
      decoration: ShapeDecoration(
        color: context.theme.appColors.primaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.s),
        ),
      ),
      child: Text(
        roleText,
        style: context.theme.appTextThemes.caption3.copyWith(
          color: context.theme.appColors.primaryAccent,
        ),
      ),
    );
  }
}

enum ActionType { remove, select }
