// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/text_editor/hooks/use_text_delta.dart';
import 'package:ion/app/components/text_editor/text_editor_preview.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_styles.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/user/follow_user_button/follow_user_button.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';

class FeedAdvancedSearchUserListItem extends HookConsumerWidget {
  const FeedAdvancedSearchUserListItem({
    required this.user,
    super.key,
  });

  final UserMetadataEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserMetadata(:about, :displayName, :name, :picture) = user.data;
    final aboutDelta = useTextDelta(about ?? '');

    return GestureDetector(
      onTap: () => ProfileRoute(pubkey: user.masterPubkey).push<void>(context),
      child: ScreenSideOffset.small(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12.0.s),
            BadgesUserListItem(
              title: Text(displayName),
              subtitle: Text(
                prefixUsername(username: name, context: context),
              ),
              masterPubkey: user.masterPubkey,
              trailing: FollowUserButton(pubkey: user.masterPubkey),
            ),
            if (about != null) ...[
              SizedBox(height: 10.0.s),
              TextEditorPreview(
                scrollable: false,
                content: aboutDelta,
                customStyles: textEditorStyles(
                  context,
                  color: context.theme.appColors.sharkText,
                ),
              ),
            ],
            SizedBox(height: 12.0.s),
          ],
        ),
      ),
    );
  }
}
