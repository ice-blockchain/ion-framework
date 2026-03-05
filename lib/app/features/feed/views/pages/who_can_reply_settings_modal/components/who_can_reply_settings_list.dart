// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/features/feed/providers/can_reply_notifier.r.dart';
import 'package:ion/app/features/feed/views/pages/who_can_reply_settings_modal/components/who_can_reply_settings_list_item.dart';

class WhoCanReplySettingsList extends ConsumerWidget {
  const WhoCanReplySettingsList({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(whoCanReplySettingsOptionsProvider);
    return state.when(
      data: (options) => ListView.separated(
        restorationId: 'who_can_reply_settings_list_scroll',
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(
          horizontal: ScreenSideOffset.defaultSmallMargin,
        ),
        itemCount: options.length,
        separatorBuilder: (_, __) => const HorizontalSeparator(),
        itemBuilder: (BuildContext context, int index) {
          final option = options[index];
          return WhoCanReplySettingsListItem(option: option);
        },
      ),
      loading: () => const ListItemsLoadingState(
        listItemsLoadingStateType: ListItemsLoadingStateType.listView,
        itemsCount: 3,
      ),
      error: (error, st) => const SizedBox(),
    );
  }
}
