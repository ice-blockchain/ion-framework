// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/role_permissions.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/encrypted_group_metadata_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/permission_item.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class TransferOwnershipPage extends HookConsumerWidget {
  const TransferOwnershipPage({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOwnerPubkey = useState<String?>(null);
    final groupMetadata = ref.watch(encryptedGroupMetadataProvider(conversationId)).valueOrNull;

    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
    final currentUserRole = currentUserMasterPubkey != null
        ? groupMetadata?.currentUserRole(currentUserMasterPubkey)
        : null;
    if (groupMetadata == null || currentUserRole == null) {
      return const SheetContent(
        body: SizedBox.shrink(),
      );
    }

    final selectedUserData = selectedOwnerPubkey.value != null
        ? ref.watch(userPreviewDataProvider(selectedOwnerPubkey.value!)).valueOrNull
        : null;

    final canConfirm = selectedOwnerPubkey.value != null;

    // Get current user role permissions as we checked already he is the owner
    final rolePermissions = RolePermissions.rolePermission(currentUserRole);

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            onBackPress: () => context.pop(),
            title: Text(context.i18n.channel_create_admin_type_owner),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 16.0.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Owner selection section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.i18n.channel_create_admin_type_owner,
                        style: context.theme.appTextThemes.caption.copyWith(
                          color: context.theme.appColors.quaternaryText,
                        ),
                      ),
                      SizedBox(height: 8.0.s),
                      GestureDetector(
                        onTap: () {
                          SelectOwnerModalRoute(conversationId: conversationId)
                              .push<String?>(context)
                              .then((result) {
                            if (result != null) {
                              selectedOwnerPubkey.value = result;
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.theme.appColors.tertiaryBackground,
                            borderRadius: BorderRadius.circular(16.0.s),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 12.0.s, vertical: 8.0.s),
                          constraints: BoxConstraints(minHeight: 60.0.s),
                          child: selectedUserData != null
                              ? BadgesUserListItem(
                                  title: Text(selectedUserData.data.trimmedDisplayName),
                                  subtitle: Text(
                                    prefixUsername(
                                      username: selectedUserData.data.name,
                                      context: context,
                                    ),
                                  ),
                                  masterPubkey: selectedOwnerPubkey.value!,
                                  contentPadding: EdgeInsets.zero,
                                  trailing: Assets.svg.iconArrowRight.icon(
                                    color: context.theme.appColors.secondaryText,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.i18n.select_new_owner,
                                      style: context.theme.appTextThemes.body.copyWith(
                                        color: context.theme.appColors.tertiaryText,
                                      ),
                                    ),
                                    Assets.svg.iconArrowRight.icon(
                                      color: context.theme.appColors.secondaryText,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.0.s),
                  // Permissions section
                  _OwnerPermissions(rolePermissions: rolePermissions),
                ],
              ),
            ),
          ),
          // Confirm button
          ScreenSideOffset.small(
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: 16.0.s),
              child: Button(
                mainAxisSize: MainAxisSize.max,
                minimumSize: Size(56.0.s, 56.0.s),
                label: Text(context.i18n.button_confirm),
                type: canConfirm ? ButtonType.primary : ButtonType.disabled,
                disabled: !canConfirm,
                onPressed: canConfirm
                    ? () {
                        TransferOwnershipConfirmModalRoute(
                          conversationId: conversationId,
                          newOwnerMasterPubkey: selectedOwnerPubkey.value!,
                          currentOwnerMasterPubkey: currentUserMasterPubkey!,
                        ).push<void>(context);
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerPermissions extends StatelessWidget {
  const _OwnerPermissions({
    required this.rolePermissions,
  });

  final List<GroupPermission> rolePermissions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.i18n.what_can_owner_do_label,
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
