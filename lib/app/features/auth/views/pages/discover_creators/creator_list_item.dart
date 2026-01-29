// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/follow_button.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';

class CreatorListItem extends ConsumerWidget {
  const CreatorListItem({
    required this.masterPubkey,
    required this.onPressed,
    required this.selected,
    super.key,
  });

  final String masterPubkey;

  final VoidCallback onPressed;

  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(masterPubkey, network: false).select(userPreviewDisplayNameSelector),
    );

    final username = ref.watch(
      userPreviewDataProvider(masterPubkey, network: false).select(userPreviewNameSelector),
    );

    return ScreenSideOffset.small(
      child: BadgesUserListItem(
        title: Text(displayName, strutStyle: const StrutStyle(forceStrutHeight: true)),
        subtitle: Text(withPrefix(input: username, textDirection: Directionality.of(context))),
        masterPubkey: masterPubkey,
        backgroundColor: context.theme.appColors.tertiaryBackground,
        contentPadding: EdgeInsets.all(12.0.s),
        borderRadius: BorderRadius.circular(16.0.s),
        isVerifiedOptimisticOnLoading: true,
        trailing: FollowButton(
          following: selected,
          onPressed: () async {
            return onPressed();
          },
        ),
        trailingPadding: EdgeInsetsDirectional.only(start: 6.0.s),
      ),
    );
  }
}
