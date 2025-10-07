// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_edit_message_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/recent_chat_tile.dart';
import 'package:ion/generated/assets.gen.dart';

class EditMessageInfo extends HookConsumerWidget {
  const EditMessageInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editMessage = ref.watch(selectedEditMessageProvider);

    if (editMessage == null) {
      return const SizedBox();
    }

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(12.0.s, 5.0.s, 20.0.s, 5.0.s),
      color: context.theme.appColors.onPrimaryAccent,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SideVerticalDivider(),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SenderSummary(masterPubkey: editMessage.eventMessage.masterPubkey, isEdit: true),
                  Text(
                    editMessage.contentDescription,
                    style: context.theme.appTextThemes.body2.copyWith(
                      color: context.theme.appColors.onTertiaryBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: ref.read(selectedEditMessageProvider.notifier).clear,
              child: Assets.svg.iconSheetClose.icon(
                size: 20.0.s,
                color: context.theme.appColors.tertiaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideVerticalDivider extends StatelessWidget {
  const _SideVerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2.0.s,
      margin: EdgeInsetsDirectional.only(end: 6.0.s),
      decoration: BoxDecoration(
        color: context.theme.appColors.primaryAccent,
        borderRadius: BorderRadius.circular(2.0.s),
      ),
    );
  }
}
