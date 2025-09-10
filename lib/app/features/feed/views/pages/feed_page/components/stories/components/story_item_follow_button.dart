import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_provider.r.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class StoryItemFollowButton extends HookConsumerWidget {
  const StoryItemFollowButton({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowUser = ref.watch(
      isCurrentUserFollowingSelectorProvider(
        pubkey,
      ),
    );
    return GestureDetector(
      onTap: () {
        ref.read(toggleFollowNotifierProvider.notifier).toggle(pubkey);
      },
      child: Container(
        width: 24.0.s,
        height: 24.0.s,
        decoration: BoxDecoration(
          color: isFollowUser ? context.theme.appColors.success : context.theme.appColors.primaryAccent,
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
