// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/pages/poll_length_time_modal/components/poll_picker_item/poll_picker_item.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class PollLengthTimeModal extends HookConsumerWidget {
  const PollLengthTimeModal({
    required this.selectedDay,
    required this.selectedHour,
    required this.onApply,
    super.key,
  });

  final int selectedDay;
  final int selectedHour;
  final void Function(int, int) onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tempSelectedDay = useState(selectedDay);
    final tempSelectedHour = useState(selectedHour);

    final dayScrollController = FixedExtentScrollController(initialItem: tempSelectedDay.value);
    final hourScrollController = FixedExtentScrollController(initialItem: tempSelectedHour.value);

    return SingleChildScrollView(
      restorationId: 'poll_length_time_modal_scroll',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            title: Text(context.i18n.poll_length_modal_title),
            actions: [
              NavigationCloseButton(
                onPressed: () {
                  context.pop();
                },
              ),
            ],
          ),
          SizedBox(height: 25.0.s),
          PollPickerItem(
            selectedDay: tempSelectedDay.value,
            selectedHour: tempSelectedHour.value,
            onDayChanged: (value) => tempSelectedDay.value = value,
            onHourChanged: (value) => tempSelectedHour.value = value,
            dayScrollController: dayScrollController,
            hourScrollController: hourScrollController,
          ),
          SizedBox(height: 25.0.s),
          ScreenSideOffset.large(
            child: Button(
              onPressed: () {
                onApply(tempSelectedDay.value, tempSelectedHour.value);
                context.pop();
              },
              type: tempSelectedDay.value == 0 && tempSelectedHour.value == 0
                  ? ButtonType.disabled
                  : ButtonType.primary,
              mainAxisSize: MainAxisSize.max,
              label: Text(
                context.i18n.button_apply,
                style: context.theme.appTextThemes.body,
              ),
            ),
          ),
          ScreenBottomOffset(
            margin: 5.0.s,
          ),
        ],
      ),
    );
  }
}
