// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/model/selectable_type.dart';
import 'package:ion/app/features/chat/views/components/type_selection_list_item.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class TypeSelectionModal<T extends SelectableType> extends HookConsumerWidget {
  const TypeSelectionModal({
    required this.title,
    required this.values,
    required this.onUpdated,
    this.initiallySelectedType,
    super.key,
  });

  final String title;

  final T? initiallySelectedType;
  final List<T> values;
  final void Function(T type) onUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = useState(initiallySelectedType);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          showBackButton: false,
          actions: const [
            NavigationCloseButton(),
          ],
          title: Text(title),
        ),
        for (final type in values)
          ScreenSideOffset.small(
            child: Column(
              children: [
                TypeSelectionListItem(
                  type: type,
                  onTap: () {
                    selectedType.value = type;
                    onUpdated(type);
                  },
                  isSelected: selectedType.value == type,
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
