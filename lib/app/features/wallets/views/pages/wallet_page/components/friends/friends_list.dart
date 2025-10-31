// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/friends_section_providers.r.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/friends/friends_list_header.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/friends/friends_list_item.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/components/friends/friends_list_loader.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/providers/wallet_page_loader_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class FriendsList extends ConsumerWidget {
  const FriendsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showFriendsSection = ref.watch(shouldShowFriendsListProvider);
    if (!showFriendsSection) {
      return const SizedBox.shrink();
    }

    final isPageLoading = ref.watch(walletPageLoaderNotifierProvider);

    final friendsPubkeys = ref.watch(
      currentUserFollowListProvider.select(
        (state) => state.valueOrNull?.masterPubkeys,
      ),
    );
    final isLoading = isPageLoading || friendsPubkeys == null;

    final footer = Column(
      children: [
        SizedBox(
          height: ScreenSideOffset.defaultSmallMargin,
        ),
        const SectionSeparator(),
      ],
    );

    return Column(
      children: [
        const SectionSeparator(),
        if (isLoading)
          FriendsListLoader(footer: footer)
        else if (friendsPubkeys.isNotEmpty)
          Column(
            children: [
              const FriendsListHeader(),
              SizedBox(
                height: FriendsListItem.height,
                child: ListView.builder(
                  padding: EdgeInsetsDirectional.only(
                    start: 4.0.s,
                    end: ScreenSideOffset.defaultSmallMargin,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: friendsPubkeys.length,
                  itemBuilder: (BuildContext context, int index) {
                    final friendPubkey = friendsPubkeys[index];

                    return FriendsListItem(
                      pubkey: friendPubkey,
                      onTap: () async {
                        final needToEnable2FA =
                            await ContactRoute(pubkey: friendPubkey).push<bool>(context);
                        if (needToEnable2FA != null && needToEnable2FA == true) {
                          await Future<void>.delayed(const Duration(seconds: 1));
                          if (context.mounted) {
                            await SecureAccountModalRoute().push<void>(context);
                          }
                        }
                      },
                    );
                  },
                ),
              ),
              footer,
            ],
          ),
      ],
    );
  }
}
