// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/group_type.dart';
import 'package:ion/app/features/chat/views/components/type_selection_list_item.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class GroupTypeSelectionModal extends HookConsumerWidget {
  const GroupTypeSelectionModal({
    required this.groupType,
    required this.onUpdated,
    super.key,
  });

  final GroupType groupType;
  final void Function(GroupType groupType) onUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroupType = useState(groupType);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          showBackButton: false,
          actions: const [
            NavigationCloseButton(),
          ],
          title: Text(context.i18n.group_create_type_title),
        ),
        for (final type in GroupType.values.toSet())
          ScreenSideOffset.small(
            child: Column(
              children: [
                TypeSelectionListItem(
                  type: type,
                  onTap: () {
                    selectedGroupType.value = type;
                    onUpdated(type);
                  },
                  isSelected: selectedGroupType.value == type,
                ),
                SizedBox(height: 16.0.s),
              ],
            ),
          ),
        const ScreenBottomOffset(),
      ],
    );
  }
}
