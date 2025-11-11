// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';
import 'package:ion/app/features/chat/e2ee/model/role_permissions.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/update_group_metadata_service.r.dart';
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/permission_item.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class ConfirmAdminRoleAssignModal extends ConsumerWidget {
  const ConfirmAdminRoleAssignModal({
    required this.conversationId,
    required this.participantMasterkey,
    super.key,
  });

  final String conversationId;
  final String participantMasterkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreviewData = ref.watch(userPreviewDataProvider(participantMasterkey)).valueOrNull;

    if (userPreviewData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsetsDirectional.only(
        top: 20.0.s,
        start: 16.0.s,
        end: 16.0.s,
        bottom: 16.0.s,
      ),
      decoration: ShapeDecoration(
        color: context.theme.appColors.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(30.0.s),
            topEnd: Radius.circular(30.0.s),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation bar
          const _AppBar(),
          SizedBox(height: 16.0.s),
          // Selected user section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.i18n.selected_user_label,
                style: context.theme.appTextThemes.caption.copyWith(
                  color: context.theme.appColors.quaternaryText,
                ),
              ),
              SizedBox(height: 8.0.s),
              BadgesUserListItem(
                title: Text(userPreviewData.data.trimmedDisplayName),
                subtitle: Text(
                  prefixUsername(username: userPreviewData.data.name, context: context),
                ),
                masterPubkey: participantMasterkey,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0.s, vertical: 8.0.s),
                backgroundColor: context.theme.appColors.tertiaryBackground,
                borderRadius: BorderRadius.circular(16.0.s),
                constraints: BoxConstraints(minHeight: 60.0.s),
                trailing: Assets.svg.iconArrowRight.icon(
                  color: context.theme.appColors.secondaryText,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0.s),
          // Permissions section
          _AdminPermissions(participantMasterkey: participantMasterkey),
          SizedBox(height: 16.0.s),
          // Confirm button
          Button(
            mainAxisSize: MainAxisSize.max,
            minimumSize: Size.square(56.0.s),
            label: Text(context.i18n.button_confirm),
            onPressed: () async {
              unawaited(
                ref.read(updateGroupMetaDataServiceProvider).promoteMemberToAdmin(
                      groupId: conversationId,
                      participantMasterPubkey: participantMasterkey,
                    ),
              );
              context.pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.maybePop();
                }
              });
            },
          ),
          SizedBox(height: 16.0.s),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Assets.svg.iconBackArrow.icon(
              size: 24.0.s,
              flipForRtl: true,
            ),
          ),
          Expanded(
            child: Text(
              context.i18n.add_administrator_title,
              textAlign: TextAlign.center,
              style: context.theme.appTextThemes.subtitle.copyWith(
                color: context.theme.appColors.primaryText,
              ),
            ),
          ),
          SizedBox.square(
            dimension: 24.0.s,
          ),
        ],
      ),
    );
  }
}

class _AdminPermissions extends StatelessWidget {
  const _AdminPermissions({
    required this.participantMasterkey,
  });

  final String participantMasterkey;

  @override
  Widget build(BuildContext context) {
    // Get admin role permissions
    final adminRole = GroupMemberRole.admin(participantMasterkey);
    final rolePermissions = RolePermissions.rolePermission(adminRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.i18n.what_can_admin_do_label,
          style: context.theme.appTextThemes.caption.copyWith(
            color: context.theme.appColors.quaternaryText,
          ),
        ),
        SizedBox(height: 12.0.s),
        Container(
          decoration: BoxDecoration(
            color: context.theme.appColors.tertiaryBackground,
            borderRadius: BorderRadius.circular(16.0.s),
          ),
          child: Column(
            children: GroupPermission.values.map((permission) {
              return PermissionItem(
                permission: permission,
                enabled: rolePermissions.contains(permission),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
