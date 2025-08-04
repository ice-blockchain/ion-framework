// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class BlockedUsersAppBar extends ConsumerWidget {
  const BlockedUsersAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsers = ref.watch(currentUserBlockListNotifierProvider).valueOrNull;
    final blockedCount = blockedUsers == null
        ? 0
        : blockedUsers.expand((e) => e.data.blockedMasterPubkeys).toSet().length;

    return SliverAppBar(
      pinned: true,
      primary: false,
      automaticallyImplyLeading: false,
      toolbarHeight: NavigationAppBar.modalHeaderHeight,
      flexibleSpace: NavigationAppBar.modal(
        onBackPress: () => context.pop(true),
        actions: [
          NavigationCloseButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          ),
        ],
        title: Text(
          blockedUsers == null
              ? context.i18n.settings_blocked_users
              : context.i18n.settings_blocked_users_title_with_counter(blockedCount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
