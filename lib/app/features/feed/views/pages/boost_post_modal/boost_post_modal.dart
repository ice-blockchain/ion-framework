// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/pages/boost_post_modal/components/active_post_boost_content.dart';
import 'package:ion/app/features/feed/views/pages/boost_post_modal/components/new_post_boost_content.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class BoostPostModal extends HookConsumerWidget {
  const BoostPostModal({
    required this.eventReference,
    required this.isBoostActive,
    super.key,
  });

  final bool isBoostActive;

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            title: Text(context.i18n.button_boost),
            actions: [
              NavigationCloseButton(color: context.theme.appColors.tertiaryText),
            ],
          ),
          if (isBoostActive)
            ActivePostBoostContent(eventReference: eventReference)
          else
            NewPostBoostContent(eventReference: eventReference),
        ],
      ),
    );
  }
}
