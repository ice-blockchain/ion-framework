// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/hooks/use_follow_notification.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

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
    final isAlwaysShowButton = useState<bool>(false);
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

    if (isFollowUser && !isAlwaysShowButton.value) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        isAlwaysShowButton.value = true;
        ref.read(toggleFollowNotifierProvider.notifier).toggle(pubkey);
      },
      child: Container(
        width: 24.0.s,
        height: 24.0.s,
        decoration: BoxDecoration(
          color: isFollowUser
              ? context.theme.appColors.success
              : context.theme.appColors.primaryAccent,
          borderRadius: BorderRadius.circular(10.0.s),
          border: Border.all(
            width: 1.s,
            color: context.theme.appColors.onPrimaryAccent,
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isFollowUser
              ? Assets.svg.iconSearchFollowers.icon(
                  color: context.theme.appColors.onPrimaryAccent,
                  size: 16.0.s,
                )
              : Assets.svg.iconLoginCreateacc.icon(
                  color: context.theme.appColors.onPrimaryAccent,
                  size: 16.0.s,
                ),
        ),
      ),
    );
  }
}
