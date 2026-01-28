// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/components/user/follow_user_button/follow_user_button.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';

class FollowListItem extends ConsumerWidget {
  const FollowListItem({
    required this.pubkey,
    this.network = false,
    this.follower,
    super.key,
  });

  final String pubkey;

  final bool network;

  final bool? follower;

  static double get itemHeight => 35.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(userPreviewDataProvider(pubkey, network: network));

    final hiddenMarker = ListCachedObjects.maybeObjectOf<ValueWithKey>(context, pubkey);
    final isHiddenElement = hiddenMarker != null;
    if (isHiddenElement) {
      return const SizedBox.shrink();
    }

    // Filter for empty users now works only for network == true.
    if (network && !data.isLoading && data.valueOrNull == null) {
      ListCachedObjects.updateObject<ValueWithKey>(context, (key: pubkey, value: 'hidden'));
      return const SizedBox.shrink();
    }

    final userPreviewData = data.valueOrNull;
    final displayName = userPreviewData?.data.trimmedDisplayName ?? '';
    final username = userPreviewData?.data.name ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.s),
      child: BadgesUserListItem(
        key: ValueKey<String>(pubkey),
        title: SizedBox(
          height: 16.0.s,
          child: Text(displayName, strutStyle: const StrutStyle(forceStrutHeight: true)),
        ),
        trailing: FollowUserButton(pubkey: pubkey, follower: follower),
        subtitle: SizedBox(
          height: 16.0.s,
          child: Text(prefixUsername(
            input: username,
            textDirection: Directionality.of(context),
          )),
        ),
        masterPubkey: pubkey,
        onTap: () => ProfileRoute(pubkey: pubkey).push<void>(context),
      ),
    );
  }
}
