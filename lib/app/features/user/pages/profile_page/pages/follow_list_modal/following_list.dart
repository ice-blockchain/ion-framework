// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/nothing_is_found/nothing_is_found.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/follow_type.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/components/follow_app_bar.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/components/follow_list_item.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/components/follow_list_loading.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/components/follow_search_bar.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/search_users_provider.r.dart';

class FollowingList extends HookConsumerWidget {
  const FollowingList({required this.pubkey, super.key});

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followeePubkeys = ref.watch(followListProvider(pubkey)).valueOrNull?.masterPubkeys;
    final searchQuery = useState('');
    final debouncedQuery = useDebounced(searchQuery.value, const Duration(milliseconds: 300)) ?? '';

    final searchPagedData = ref
        .watch(
          searchUsersProvider(
            query: debouncedQuery,
            followedByPubkey: pubkey,
            includeCurrentUser: true,
          ),
        )
        .valueOrNull;

    final searchMasterPubkeys = searchPagedData?.masterPubkeys;

    return LoadMoreBuilder(
      hasMore: searchPagedData?.hasMore ?? false,
      onLoadMore: () => ref
          .read(
            searchUsersProvider(
              query: debouncedQuery,
              followedByPubkey: pubkey,
              includeCurrentUser: true,
            ).notifier,
          )
          .loadMore(),
      slivers: [
        FollowAppBar(
          title: FollowType.following.getTitleWithCounter(context, followeePubkeys?.length ?? 0),
        ),
        FollowSearchBar(onTextChanged: (query) => searchQuery.value = query),
        if (searchQuery.value.isNotEmpty)
          if (searchMasterPubkeys == null)
            const FollowListLoading()
          else if (searchMasterPubkeys.isEmpty)
            const NothingIsFound()
          else
            SliverList.builder(
              itemCount: searchMasterPubkeys.length,
              itemBuilder: (context, index) => ScreenSideOffset.small(
                child: FollowListItem(
                  key: ValueKey<String>(searchMasterPubkeys[index]),
                  pubkey: searchMasterPubkeys[index],
                ),
              ),
            )
        else if (followeePubkeys != null)
          SliverList.builder(
            itemCount: followeePubkeys.length,
            itemBuilder: (context, index) => ScreenSideOffset.small(
              child: FollowListItem(
                key: ValueKey<String>(followeePubkeys[index]),
                pubkey: followeePubkeys[index],
                network: true,
              ),
            ),
          )
        else
          const FollowListLoading(),
        SliverPadding(padding: EdgeInsetsDirectional.only(bottom: 32.0.s)),
      ],
    );
  }
}
