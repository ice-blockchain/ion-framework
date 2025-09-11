// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/user_chat_privacy_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/components/selectable_user_list_item.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class FollowingUsers extends ConsumerWidget {
  const FollowingUsers({
    required this.onUserSelected,
    this.selectedPubkeys = const [],
    this.selectable = false,
    this.controlChatPrivacy = false,
    super.key,
  });

  final bool selectable;
  final bool controlChatPrivacy;
  final List<String> selectedPubkeys;
  final void Function(UserMetadataEntity user) onUserSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followedPeople = ref.watch(currentUserFollowListWithMetadataProvider);

    return followedPeople.maybeWhen(
      data: (people) {
        if (people.isEmpty) return const _NoUserView();
        final masterPubkeys = people.map((e) => e.pubkey).toList();

        return SliverList.builder(
          itemBuilder: (context, index) {
            final userMetadata = people[index];
            final masterPubkey = masterPubkeys.elementAt(index);

            final bool canSendMessage;
            if (controlChatPrivacy) {
              canSendMessage = ref.watch(canSendMessageProvider(masterPubkey)).valueOrNull ?? false;
            } else {
              canSendMessage = true;
            }

            return canSendMessage
                ? SelectableUserListItem(
                    userMetadata: userMetadata,
                    selectable: selectable,
                    onUserSelected: onUserSelected,
                    selectedPubkeys: selectedPubkeys,
                    canSendMessage: canSendMessage,
                  )
                : const SizedBox.shrink();
          },
          itemCount: masterPubkeys.length,
        );
      },
      loading: () => ListItemsLoadingState(
        padding: EdgeInsets.symmetric(vertical: 8.0.s),
        listItemsLoadingStateType: ListItemsLoadingStateType.scrollView,
      ),
      orElse: () => const _NoUserView(),
    );
  }
}

class _NoUserView extends StatelessWidget {
  const _NoUserView();

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: ScreenSideOffset.small(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Assets.svg.walletChatNewchat.icon(size: 48.0.s),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0.s, horizontal: 78.0.s),
              child: Text(
                context.i18n.users_search,
                style: context.theme.appTextThemes.caption2.copyWith(
                  color: context.theme.appColors.onTertiaryBackground,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(
              flex: 2,
            ),
          ],
        ),
      ),
    );
  }
}
