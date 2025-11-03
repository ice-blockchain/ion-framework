// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';

class TextMessageLimitLabel extends HookConsumerWidget {
  const TextMessageLimitLabel({
    required this.textEditingController,
    super.key,
  });

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exceededLimit = useState<int>(0);

    useEffect(
      () {
        void onTextChanged() {
          exceededLimit.value =
              textEditingController.text.length - EncryptedDirectMessageData.textMessageLimit;
        }

        textEditingController.addListener(onTextChanged);
        return () => textEditingController.removeListener(onTextChanged);
      },
      [textEditingController],
    );

    if (exceededLimit.value > 0) {
      return PositionedDirectional(
        top: 0.0.s,
        end: 8.0.s,
        child: Text(
          style: context.theme.appTextThemes.caption2.copyWith(
            color: context.theme.appColors.attentionRed,
          ),
          '-${exceededLimit.value}',
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
