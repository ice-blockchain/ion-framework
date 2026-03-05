// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class CancelCreationModal extends ConsumerWidget {
  const CancelCreationModal({
    required this.title,
    required this.onCancel,
    super.key,
  });

  final String title;
  final VoidCallback onCancel;

  static double get buttonsSize => 56.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonMinimalSize = Size(buttonsSize, buttonsSize);

    return ScreenSideOffset.small(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 48.0.s),
          InfoCard(
            iconAsset: Assets.svg.actionCreatepostDeletepost,
            title: title,
            description: context.i18n.cancel_creation_description,
          ),
          SizedBox(height: 28.0.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Button.compact(
                  type: ButtonType.outlined,
                  label: Text(
                    context.i18n.button_back,
                  ),
                  onPressed: () {
                    context.pop();
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
                    context.i18n.button_cancel,
                  ),
                  onPressed: () {
                    onCancel();
                    context.pop();
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
    );
  }
}
