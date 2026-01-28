// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/text_editor/hooks/use_text_delta.dart';
import 'package:ion/app/components/text_editor/text_editor_preview.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_styles.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/components/user/follow_user_button/follow_user_button.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';

class FeedAdvancedSearchUserListItem extends HookConsumerWidget {
  const FeedAdvancedSearchUserListItem({
    required this.masterPubkey,
    super.key,
  });

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Using ListEntityObjects here to prevent scroll up issue,
    // because the item height is not fixed for this case ("about" part hight is not constant).
    final userPreviewData = ref.watch(
          userPreviewDataProvider(masterPubkey, network: false).select((value) {
            final entity = value.valueOrNull;
            if (entity != null) {
              ListCachedObjects.updateObject<UserPreviewEntity>(ref.context, entity);
            }
            return entity;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<UserPreviewEntity>(ref.context, masterPubkey);

    final about = userPreviewData is UserMetadataEntity ? userPreviewData.data.about : null;

    final displayName = userPreviewData?.data.trimmedDisplayName ?? '';
    final name = userPreviewData?.data.name ?? '';

    final aboutDelta = useTextDelta(about ?? '');

    if (userPreviewData == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => ProfileRoute(pubkey: masterPubkey).push<void>(context),
      child: ScreenSideOffset.small(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12.0.s),
            BadgesUserListItem(
              title: Text(displayName, strutStyle: const StrutStyle(forceStrutHeight: true)),
              subtitle: Text(
                prefixUsername(
                  input: name,
                  textDirection: Directionality.of(context),
                ),
              ),
              masterPubkey: masterPubkey,
              trailing: FollowUserButton(pubkey: masterPubkey),
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
