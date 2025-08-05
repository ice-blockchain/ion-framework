// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/follow_button.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/views/pages/unfollow_user_page.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_provider.r.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';

class FollowUserButton extends ConsumerWidget {
  const FollowUserButton({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUser = ref.watch(isCurrentUserSelectorProvider(pubkey));

    if (isCurrentUser) {
      return const SizedBox.shrink();
    }

    ref.displayErrors(toggleFollowNotifierProvider, excludedExceptions: {UserRelaysNotFoundException});

    final following = ref.watch(isCurrentUserFollowingSelectorProvider(pubkey));
    final isCurrentUserFollowed = ref.watch(isCurrentUserFollowedProvider(pubkey));

    return FollowButton(
      onPressed: () {
        if (following) {
          showSimpleBottomSheet<void>(
            context: context,
            child: UnfollowUserModal(
              pubkey: pubkey,
            ),
          );
        } else {
          ref.read(toggleFollowNotifierProvider.notifier).toggle(pubkey);
        }
      },
      following: following,
      followLabel: isCurrentUserFollowed && !following ? context.i18n.button_follow_back : null,
    );
  }
}
