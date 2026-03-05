// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/components/blocked_user_list_item.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/components/blocked_users_app_bar.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/components/blocked_users_search_bar.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class BlockedUsersModal extends HookConsumerWidget {
  const BlockedUsersModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockListState = ref.watch(currentUserBlockListNotifierProvider);

    return SheetContent(
      topPadding: 0,
      body: CustomScrollView(
        slivers: [
          const BlockedUsersAppBar(),
          const BlockedUsersSearchBar(),
          blockListState.maybeWhen(
            data: (blockedUsers) {
              final pubkeys = blockedUsers
                  .expand((blockedUser) => blockedUser.data.blockedMasterPubkeys)
                  .toList();

              return SliverList.separated(
                separatorBuilder: (_, __) => SizedBox(height: 16.0.s),
                itemCount: pubkeys.length,
                itemBuilder: (context, index) => ScreenSideOffset.small(
                  child: BlockedUserListItem(pubkey: pubkeys[index]),
                ),
              );
            },
            orElse: () => SliverToBoxAdapter(
              child: ListItemsLoadingState(
                itemHeight: BlockedUserListItem.itemHeight,
                padding: EdgeInsets.zero,
                listItemsLoadingStateType: ListItemsLoadingStateType.scrollView,
              ),
            ),
          ),
          SliverPadding(padding: EdgeInsetsDirectional.only(bottom: 32.0.s)),
        ],
      ),
    );
  }
}
