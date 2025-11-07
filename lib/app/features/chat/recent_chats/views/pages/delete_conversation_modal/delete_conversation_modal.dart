// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/providers/e2ee_delete_event_provider.r.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class DeleteConversationModal extends ConsumerWidget {
  const DeleteConversationModal({required this.conversationIds, super.key});

  final List<String> conversationIds;

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
                title: conversationIds.length > 1
                    ? context.i18n.chat_delete_modal_title
                    : context.i18n.chat_delete_modal_title_single,
                description: conversationIds.length > 1
                    ? context.i18n.chat_delete_modal_description
                    : context.i18n.chat_delete_modal_description_single,
                iconAsset: Assets.svg.actionCreatepostDeletepost,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Button.compact(
                    type: ButtonType.outlined,
                    label: Text(
                      context.i18n.button_for_everyone,
                    ),
                    onPressed: () async {
                      ref.read(
                        e2eeDeleteConversationProvider(
                          conversationIds: conversationIds,
                          forEveryone: true,
                        ),
                      );
                      context.pop(true);
                    },
                    minimumSize: buttonMinimalSize,
                  ),
                ),
                SizedBox(
                  width: 15.0.s,
                ),
                Expanded(
                  child: Button.compact(
                    label: Text(
                      context.i18n.button_for_me,
                    ),
                    onPressed: () async {
                      ref.read(e2eeDeleteConversationProvider(conversationIds: conversationIds));
                      context.pop(true);
                    },
                    minimumSize: buttonMinimalSize,
                    backgroundColor: context.theme.appColors.attentionRed,
                  ),
                ),
              ],
            ),
            ScreenBottomOffset(),
          ],
        ),
      ),
    );
  }
}
