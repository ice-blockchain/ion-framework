// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/search/views/components/search_history/search_list_item_loading.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';

class SearchHistoryUserListItem extends ConsumerWidget {
  const SearchHistoryUserListItem({required this.pubkey, required this.onTap, super.key});

  final String pubkey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreviewData = ref.watch(userPreviewDataProvider(pubkey));
    return userPreviewData.maybeWhen(
      data: (userPreviewData) => userPreviewData != null
          ? GestureDetector(
              onTap: onTap,
              child: _UserListItem(userPreviewData: userPreviewData),
            )
          : const SizedBox.shrink(),
      orElse: ListItemLoading.new,
    );
  }
}

class _UserListItem extends StatelessWidget {
  const _UserListItem({required this.userPreviewData});

  final UserPreviewEntity userPreviewData;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 65.0.s,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IonConnectAvatar(size: 65.0.s, masterPubkey: userPreviewData.masterPubkey),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userPreviewData.data.trimmedDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.appTextThemes.caption3.copyWith(
                  color: context.theme.appColors.primaryText,
                ),
              ),
              Text(
                prefixUsername(username: userPreviewData.data.name, context: context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.appTextThemes.caption3.copyWith(
                  color: context.theme.appColors.tertiaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
