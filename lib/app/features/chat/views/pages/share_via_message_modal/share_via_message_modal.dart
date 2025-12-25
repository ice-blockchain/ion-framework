// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/views/pages/share_via_message_modal/components/share_options.dart';
import 'package:ion/app/features/chat/views/pages/share_via_message_modal/components/share_send_button.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/user_picker_sheet.dart';
import 'package:ion/app/hooks/use_selected_state.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class ShareViaMessageModal extends HookWidget {
  const ShareViaMessageModal({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context) {
    final (selectedPubkeys, togglePubkeySelection) = useSelectedState<String>();

    return SheetContent(
      body: Column(
        children: [
          Flexible(
            child: UserPickerSheet(
              selectable: true,
              controlPrivacy: true,
              selectedPubkeys: selectedPubkeys,
              navigationBar: NavigationAppBar.modal(
                title: Text(context.i18n.feed_share_via),
                actions: const [NavigationCloseButton()],
                showBackButton: false,
              ),
              onUserSelected: togglePubkeySelection,
            ),
          ),
          const HorizontalSeparator(),
          SizedBox(
            height: 110.0.s,
            child: selectedPubkeys.isEmpty
                ? ShareOptions(eventReference: eventReference)
                : ShareSendButton(
                    masterPubkeys: selectedPubkeys,
                    eventReference: eventReference,
                  ),
          ),
        ],
      ),
    );
  }
}
