// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/views/pages/unfollow_user_page.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/hooks/use_follow_notification.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class ProfileMainAction extends HookConsumerWidget {
  const ProfileMainAction({
    required this.pubkey,
    required this.profileMode,
    super.key,
  });

  final String pubkey;
  final ProfileMode profileMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profileMode != ProfileMode.dark) {
      return const SizedBox.shrink();
    }

    final isCurrentUserProfile = ref.watch(isCurrentUserSelectorProvider(pubkey));
    final following = ref.watch(isCurrentUserFollowingSelectorProvider(pubkey));
    final username = ref.watch(userPreviewDataProvider(pubkey).select(userPreviewNameSelector));

    useFollowNotifications(
      context,
      ref,
      pubkey,
      username,
    );

    return GestureDetector(
      onTap: () => _handleAction(context, ref, isCurrentUserProfile, following),
      child: Container(
        width: 24.0.s,
        height: 24.0.s,
        padding: EdgeInsets.all(3.0.s),
        decoration: ShapeDecoration(
          color: _getColor(context, isCurrentUserProfile, following),
          shape: const OvalBorder(),
        ),
        child: Center(
          child: _getIcon(context, isCurrentUserProfile, following),
        ),
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    bool isCurrentUserProfile,
    bool following,
  ) {
    if (isCurrentUserProfile) {
      // Navigate to edit profile
      ProfileEditRoute().push<void>(context);
    } else if (following) {
      // Show unfollow modal
      showSimpleBottomSheet<void>(
        context: context,
        child: UnfollowUserModal(
          pubkey: pubkey,
        ),
      );
    } else {
      // Follow user
      ref.read(toggleFollowNotifierProvider.notifier).toggle(pubkey);
    }
  }

  Color _getColor(BuildContext context, bool isCurrentUserProfile, bool following) {
    if (isCurrentUserProfile) {
      return context.theme.appColors.primaryAccent;
    } else if (following) {
      return context.theme.appColors.success;
    } else {
      return context.theme.appColors.primaryAccent;
    }
  }

  Widget _getIcon(BuildContext context, bool isCurrentUserProfile, bool following) {
    if (isCurrentUserProfile) {
      return Assets.svg.iconEditLink.icon(
        size: 18.0.s,
        color: context.theme.appColors.secondaryBackground,
      );
    } else if (following) {
      return Assets.svg.iconSearchFollowers.icon(
        size: 18.0.s,
        color: context.theme.appColors.secondaryBackground,
      );
    } else {
      return Assets.svg.iconSearchFollow.icon(
        size: 18.0.s,
        color: context.theme.appColors.secondaryBackground,
      );
    }
  }
}
