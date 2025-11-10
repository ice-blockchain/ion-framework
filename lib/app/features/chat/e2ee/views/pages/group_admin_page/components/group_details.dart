// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';
import 'package:ion/app/features/chat/e2ee/model/group_metadata.f.dart';
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/edit_group_button.dart';
import 'package:ion/generated/assets.gen.dart';

class GroupDetails extends ConsumerWidget {
  const GroupDetails({
    required this.conversationId,
    required this.groupName,
    required this.memberCount,
    this.currentUserRole,
    super.key,
  });

  final String conversationId;
  final String groupName;
  final int memberCount;
  final GroupMemberRole? currentUserRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenSideOffset.small(
      child: Column(
        children: [
          Text(
            groupName,
            style: context.theme.appTextThemes.title,
            textAlign: TextAlign.center,
          ),
          if (currentUserRole?.canEditGroup ?? false) ...[
            SizedBox(height: 12.0.s),
            EditGroupButton(conversationId: conversationId),
            SizedBox(height: 14.0.s),
          ],
          SizedBox(height: 2.0.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Assets.svg.iconChannelMembers.icon(
                size: 16.0.s,
                color: context.theme.appColors.quaternaryText,
              ),
              SizedBox(width: 6.0.s),
              Text(
                context.i18n.members_count(memberCount),
                style: context.theme.appTextThemes.body2.copyWith(
                  color: context.theme.appColors.quaternaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
