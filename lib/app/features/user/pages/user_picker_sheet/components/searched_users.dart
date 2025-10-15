// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/nothing_is_found/nothing_is_found.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/user_chat_privacy_provider.r.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/components/selectable_user_list_item.dart';

class SearchedUsers extends ConsumerWidget {
  const SearchedUsers({
    required this.masterPubkeys,
    required this.onUserSelected,
    this.selectable = false,
    this.controlChatPrivacy = false,
    this.selectedPubkeys = const [],
    super.key,
  });

  final List<String>? masterPubkeys;
  final void Function(UserPreviewEntity user) onUserSelected;
  final bool selectable;
  final bool controlChatPrivacy;
  final List<String> selectedPubkeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchedMasterPubkeys = masterPubkeys;

    if (searchedMasterPubkeys == null) {
      return ListItemsLoadingState(
        padding: EdgeInsets.symmetric(vertical: 8.0.s),
        listItemsLoadingStateType: ListItemsLoadingStateType.scrollView,
      );
    }

    if (searchedMasterPubkeys.isEmpty) {
      return const NothingIsFound();
    }

    return SliverList.builder(
      itemCount: searchedMasterPubkeys.length,
      itemBuilder: (BuildContext context, int index) {
        final masterPubkey = searchedMasterPubkeys.elementAt(index);
        final bool canSendMessage;
        if (controlChatPrivacy) {
          canSendMessage = ref.watch(canSendMessageProvider(masterPubkey)).valueOrNull ?? false;
        } else {
          canSendMessage = true;
        }
        return SelectableUserListItem(
          selectable: selectable,
          masterPubkey: masterPubkey,
          canSendMessage: canSendMessage,
          onUserSelected: onUserSelected,
          selectedPubkeys: selectedPubkeys,
        );
      },
    );
  }
}
