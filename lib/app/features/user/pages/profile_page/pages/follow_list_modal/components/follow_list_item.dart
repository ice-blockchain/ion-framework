// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/components/user/follow_user_button/follow_user_button.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';

class FollowListItem extends HookConsumerWidget {
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

  static final _loadedAsNullPubkeys = <String>{};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadState = ref.watch(
      userPreviewDataProvider(pubkey, network: network).select(
        (state) => (
          isLoaded: state.hasValue,
          value: state.valueOrNull,
        ),
      ),
    );

    final isLoaded = loadState.isLoaded;
    final loadedValue = loadState.value;

    if (isLoaded && loadedValue == null) {
      _loadedAsNullPubkeys.add(pubkey);
    } else if (loadedValue != null) {
      _loadedAsNullPubkeys.remove(pubkey);
      ListCachedObjects.updateObject<UserPreviewEntity>(context, loadedValue);
    }

    if (_loadedAsNullPubkeys.contains(pubkey)) {
      return const SizedBox.shrink();
    }

    final userPreviewData =
        loadedValue ?? ListCachedObjects.maybeObjectOf<UserPreviewEntity>(context, pubkey);

    final displayName = userPreviewData?.data.trimmedDisplayName ?? '';
    final username = userPreviewData?.data.name ?? '';
    if (isLoaded && (displayName.isEmpty || username.isEmpty)) {
      return const SizedBox.shrink();
    }

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
          child: Text(prefixUsername(username: username, context: context)),
        ),
        masterPubkey: pubkey,
        onTap: () => ProfileRoute(pubkey: pubkey).push<void>(context),
      ),
    );
  }
}
