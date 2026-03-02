// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message_service.r.dart';
import 'package:ion/app/features/core/views/pages/error_modal.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:receive_sharing/receive_sharing.dart';

class ShareExternalContentSendButton extends HookConsumerWidget {
  const ShareExternalContentSendButton({
    required this.masterPubkeys,
    required this.content,
    super.key,
  });

  final List<String> masterPubkeys;
  final SharedContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = useState(false);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          top: 16.0.s,
          start: 44.0.s,
          end: 44.0.s,
        ),
        child: Button(
          disabled: loading.value,
          mainAxisSize: MainAxisSize.max,
          minimumSize: Size(56.0.s, 56.0.s),
          trailingIcon: loading.value
              ? const IONLoadingIndicator()
              : Assets.svg.iconButtonNext.icon(color: context.theme.appColors.onPrimaryAccent),
          label: Text(
            context.i18n.feed_send,
          ),
          onPressed: () async {
            loading.value = true;
            try {
              final messageContent = switch (content) {
                SharedText(:final text) => text,
              };
              final chatService = await ref.read(sendChatMessageServiceProvider.future);
              await Future.wait(
                masterPubkeys.map(
                  (masterPubkey) => chatService.send(
                    receiverPubkey: masterPubkey,
                    content: messageContent,
                  ),
                ),
              );
              if (context.mounted) {
                context.pop();
              }
            } catch (error) {
              if (context.mounted) {
                showErrorModal(context, error);
              }
            } finally {
              loading.value = false;
            }
          },
        ),
      ),
    );
  }
}
