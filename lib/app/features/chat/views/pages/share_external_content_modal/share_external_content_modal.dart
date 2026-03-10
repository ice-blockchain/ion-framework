// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/views/pages/share_external_content_modal/components/share_external_content_options.dart';
import 'package:ion/app/features/chat/views/pages/share_external_content_modal/components/share_external_content_send_button.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/user_picker_sheet.dart';
import 'package:ion/app/hooks/use_selected_state.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/services/sharing_intent/shared_content.dart';

class ShareExternalContentModal extends HookWidget {
  const ShareExternalContentModal({
    required this.content,
    super.key,
  });

  final SharedContent content;

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
                ? ShareExternalContentOptions(content: content)
                : ShareExternalContentSendButton(
                    masterPubkeys: selectedPubkeys,
                    content: content,
                  ),
          ),
        ],
      ),
    );
  }
}
