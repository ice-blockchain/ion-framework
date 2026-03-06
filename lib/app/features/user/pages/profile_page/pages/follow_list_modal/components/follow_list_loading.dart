// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/components/follow_list_item.dart';

class FollowListLoading extends StatelessWidget {
  const FollowListLoading({super.key, this.itemsCount});

  final int? itemsCount;

  @override
  Widget build(BuildContext context) {
    return ListItemsLoadingState(
      itemHeight: FollowListItem.itemHeight,
      itemsCount: itemsCount,
      padding: EdgeInsets.symmetric(vertical: 8.0.s),
      listItemsLoadingStateType: ListItemsLoadingStateType.scrollView,
    );
  }
}
