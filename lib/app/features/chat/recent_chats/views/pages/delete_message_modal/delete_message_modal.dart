// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class DeleteMessageModal extends ConsumerWidget {
  const DeleteMessageModal({required this.isMe, super.key});

  final bool isMe;

  static double get buttonsSize => 56.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonMinimalSize = Size(buttonsSize, buttonsSize);

    return SheetContent(
      body: ScreenSideOffset.small(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(top: 32.0.s, bottom: 28.0.s),
              child: InfoCard(
                title: context.i18n.chat_message_delete_modal_title_single,
                description: context.i18n.chat_message_delete_modal_description_single,
                iconAsset: Assets.svg.actionCreatepostDeletepost,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isMe)
                  Expanded(
                    child: Button.compact(
                      type: ButtonType.outlined,
                      label: Text(
                        context.i18n.button_for_everyone,
                      ),
                      onPressed: () {
                        context.pop(true);
                      },
                      minimumSize: buttonMinimalSize,
                    ),
                  ),
                if (isMe)
                  SizedBox(
                    width: 15.0.s,
                  ),
                Expanded(
                  child: Button.compact(
                    label: Text(
                      context.i18n.button_for_me,
                    ),
                    onPressed: () {
                      context.pop(false);
                    },
                    minimumSize: buttonMinimalSize,
                    backgroundColor: context.theme.appColors.attentionRed,
                  ),
                ),
              ],
            ),
            const ScreenBottomOffset(),
          ],
        ),
      ),
    );
  }
}
