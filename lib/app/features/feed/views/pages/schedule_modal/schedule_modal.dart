// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class ScheduleModal extends HookWidget {
  const ScheduleModal({
    required this.initialDate,
    this.minimumDate,
    super.key,
  });

  final DateTime initialDate;
  final DateTime? minimumDate;

  @override
  Widget build(BuildContext context) {
    final selectedDate = useState<DateTime>(initialDate);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          title: Text(context.i18n.schedule_modal_nav_title),
          actions: const [NavigationCloseButton()],
          onBackPress: () => context.pop(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 26.0.s),
          child: SizedBox(
            height: 178.0.s,
            child: CupertinoDatePicker(
              initialDateTime: selectedDate.value,
              use24hFormat: true,
              onDateTimeChanged: (DateTime newDateTime) {
                selectedDate.value = newDateTime;
              },
              minimumDate: minimumDate,
            ),
          ),
        ),
        ScreenSideOffset.large(
          child: Button(
            onPressed: () {
              context.pop(selectedDate.value);
            },
            mainAxisSize: MainAxisSize.max,
            label: Text(
              context.i18n.button_schedule,
              style: context.theme.appTextThemes.body,
            ),
          ),
        ),
        const ScreenBottomOffset(),
      ],
    );
  }
}
