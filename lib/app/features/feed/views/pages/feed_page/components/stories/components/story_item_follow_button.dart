// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/follow_button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/hooks/use_follow_notification.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';

class StoryItemFollowButton extends HookConsumerWidget {
  const StoryItemFollowButton({
    required this.pubkey,
    required this.username,
    super.key,
  });

  final String pubkey;
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(currentUserFollowListProvider.select((state) => state.isLoading));
    if (isLoading) {
      return const SizedBox.shrink();
    }

    final isFollowUser = ref.watch(
      isCurrentUserFollowingSelectorProvider(
        pubkey,
      ),
    );

    ref.displayErrors(toggleFollowNotifierProvider);

    useFollowNotifications(
      context,
      ref,
      pubkey,
      username,
    );

    return FollowButton(
      onPressed: () async {
        await ref.read(toggleFollowNotifierProvider.notifier).toggle(pubkey);
      },
      isFollowing: isFollowUser,
      visibility: FollowButtonVisibility.keepUntilRefresh,
      decoration: FollowButtonDecoration(
        foregroundColor: context.theme.appColors.onPrimaryAccent,
        contentPadding: EdgeInsets.all(4.0.s),
        showLabel: false,
        color: context.theme.appColors.primaryAccent,
        borderRadius: BorderRadius.circular(10.0.s),
        border: Border.all(
          width: 1.s,
        ),
      ),
      decorationWhenFollowing: FollowButtonDecoration(
        foregroundColor: context.theme.appColors.onPrimaryAccent,
        contentPadding: EdgeInsets.all(4.0.s),
        showLabel: false,
        color: context.theme.appColors.success,
        borderRadius: BorderRadius.circular(10.0.s),
        border: Border.all(
          width: 1.s,
        ),
      ),
    );
  }
}
