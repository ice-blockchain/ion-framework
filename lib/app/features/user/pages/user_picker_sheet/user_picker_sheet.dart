// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/components/following_users.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/components/searched_users.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/search_users_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';

class UserPickerSheet extends HookConsumerWidget {
  const UserPickerSheet({
    required this.navigationBar,
    required this.onUserSelected,
    super.key,
    this.header,
    this.footer,
    this.cacheStrategy,
    this.expirationDuration,
    this.selectable = false,
    this.controlPrivacy = false,
    this.selectedPubkeys = const [],
  });

  final NavigationAppBar navigationBar;
  final List<String> selectedPubkeys;
  final bool selectable;
  final bool controlPrivacy;
  final Duration? expirationDuration;
  final DatabaseCacheStrategy? cacheStrategy;
  final void Function(String masterPubkey) onUserSelected;

  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchUsersQueryProvider);
    final debouncedQuery = useDebounced(searchQuery, const Duration(milliseconds: 300)) ?? '';

    final searchResults = ref.watch(
      searchUsersProvider(
        query: debouncedQuery,
        cacheStrategy: cacheStrategy,
        expirationDuration: expirationDuration,
      ),
    );

    final currentPubkey = ref.watch(currentPubkeySelectorProvider);

    final followListState = ref.watch(userFollowListWithMetadataProvider(currentPubkey!));
    final showFollowingUsers = debouncedQuery.isEmpty;

    return LoadMoreBuilder(
      slivers: [
        SliverAppBar(
          primary: false,
          flexibleSpace: navigationBar,
          automaticallyImplyLeading: false,
          toolbarHeight: NavigationAppBar.modalHeaderHeight,
          pinned: true,
        ),
        PinnedHeaderSliver(
          child: ColoredBox(
            color: context.theme.appColors.onPrimaryAccent,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8.0.s,
                horizontal: ScreenSideOffset.defaultSmallMargin,
              ),
              child: SearchInput(
                textInputAction: TextInputAction.search,
                onTextChanged: (text) {
                  ref.read(searchUsersQueryProvider.notifier).text = text;
                },
              ),
            ),
          ),
        ),
        if (header != null) header!,
        if (showFollowingUsers)
          FollowingUsers(
            selectable: selectable,
            onUserSelected: onUserSelected,
            controlChatPrivacy: controlPrivacy,
            selectedPubkeys: selectedPubkeys,
          )
        else
          SearchedUsers(
            selectable: selectable,
            controlChatPrivacy: controlPrivacy,
            onUserSelected: onUserSelected,
            selectedPubkeys: selectedPubkeys,
            masterPubkeys: searchResults.valueOrNull?.masterPubkeys,
          ),
        SliverToBoxAdapter(child: SizedBox(height: 8.0.s)),
        if (footer != null) footer!,
      ],
      onLoadMore: showFollowingUsers
          ? ref.read(userFollowListWithMetadataProvider(currentPubkey).notifier).fetchEntities
          : ref.read(searchUsersProvider(query: debouncedQuery).notifier).loadMore,
      hasMore: showFollowingUsers
          ? followListState.valueOrNull?.hasMore ?? false
          : searchResults.valueOrNull?.hasMore ?? false,
    );
  }
}
