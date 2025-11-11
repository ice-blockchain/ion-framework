// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/group_type.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/encrypted_group_metadata_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class GroupAdminsModal extends HookConsumerWidget {
  const GroupAdminsModal({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupMetadata = ref.watch(encryptedGroupMetadataProvider(conversationId)).valueOrNull;

    final adminsAndOwners = groupMetadata?.members
        .where((member) => member is GroupMemberRoleOwner || member is GroupMemberRoleAdmin)
        .toList();

    if (adminsAndOwners == null || adminsAndOwners.isEmpty) {
      return const SizedBox.shrink();
    }

    // Count admins (excluding owner)
    final adminCount = adminsAndOwners.length - 1;
    // Check if we've reached the max admin limit for encrypted groups
    final maxAdmins = GroupType.encrypted.maxAdmins;
    final isMaxAdminsReached = maxAdmins != null && adminCount >= maxAdmins;

    // Sort so owner comes first
    final sortedAdmins = [...adminsAndOwners]..sort((a, b) {
        final aIsOwner = a is GroupMemberRoleOwner;
        final bIsOwner = b is GroupMemberRoleOwner;
        if (aIsOwner && !bIsOwner) {
          return -1;
        }
        if (!aIsOwner && bIsOwner) {
          return 1;
        }
        return 0;
      });

    return SheetContent(
      body: SizedBox(
        height: 400.0.s,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              primary: false,
              flexibleSpace: NavigationAppBar.modal(
                showBackButton: false,
                actions: [
                  NavigationCloseButton(
                    onPressed: () => context.pop(),
                  ),
                ],
                title: Text(context.i18n.group_admins_modal_title),
              ),
              automaticallyImplyLeading: false,
              toolbarHeight: NavigationAppBar.modalHeaderHeight,
              pinned: true,
            ),
            PinnedHeaderSliver(
              child: ScreenSideOffset.small(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: 8.0.s, bottom: 16.0.s),
                  child: Button(
                    mainAxisSize: MainAxisSize.max,
                    minimumSize: Size(56.0.s, 56.0.s),
                    leadingIcon: Assets.svg.iconPlusCreatechannel.icon(
                      color: context.theme.appColors.onPrimaryAccent,
                    ),
                    label: Text(
                      context.i18n.channel_create_admins_action,
                    ),
                    type: isMaxAdminsReached ? ButtonType.disabled : ButtonType.primary,
                    disabled: isMaxAdminsReached,
                    onPressed: isMaxAdminsReached
                        ? null
                        : () {
                            SelectAdministratorModalRoute(conversationId: conversationId)
                                .push<void>(context);
                          },
                  ),
                ),
              ),
            ),
            SliverList.separated(
              separatorBuilder: (BuildContext _, int __) => SizedBox(height: 16.0.s),
              itemCount: sortedAdmins.length,
              itemBuilder: (BuildContext context, int index) {
                final adminRole = sortedAdmins[index];
                final participantMasterkey = adminRole.masterPubkey;

                return ScreenSideOffset.small(
                  child: _GroupAdminCard(
                    conversationId: conversationId,
                    participantMasterkey: participantMasterkey,
                    role: adminRole,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupAdminCard extends ConsumerWidget {
  const _GroupAdminCard({
    required this.conversationId,
    required this.participantMasterkey,
    required this.role,
  });

  final String conversationId;
  final String participantMasterkey;
  final GroupMemberRole role;

  static double get itemHeight => 60.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreviewData = ref.watch(userPreviewDataProvider(participantMasterkey));

    return userPreviewData.maybeWhen(
      data: (userMetadata) {
        if (userMetadata == null) {
          return const SizedBox.shrink();
        }

        final roleText = role is GroupMemberRoleOwner
            ? context.i18n.channel_create_admin_type_owner
            : context.i18n.channel_create_admin_type_admin;

        final isOwner = role is GroupMemberRoleOwner;

        return BadgesUserListItem(
          onTap: isOwner
              ? () {
                  ManageOwnerRoleModalRoute(conversationId: conversationId).push<void>(context);
                }
              : () {
                  ManageAdminRoleModalRoute(
                    conversationId: conversationId,
                    participantMasterkey: participantMasterkey,
                  ).push<void>(context);
                },
          title: Text(userMetadata.data.trimmedDisplayName),
          subtitle: Text(prefixUsername(username: userMetadata.data.name, context: context)),
          masterPubkey: participantMasterkey,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.0.s, vertical: 8.0.s),
          backgroundColor: context.theme.appColors.tertiaryBackground,
          borderRadius: BorderRadius.circular(16.0.s),
          constraints: BoxConstraints(minHeight: itemHeight),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                roleText,
                style: context.theme.appTextThemes.body
                    .copyWith(color: context.theme.appColors.primaryAccent),
              ),
              Padding(
                padding: EdgeInsets.all(4.0.s),
                child: Assets.svg.iconArrowRight.icon(color: context.theme.appColors.secondaryText),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
