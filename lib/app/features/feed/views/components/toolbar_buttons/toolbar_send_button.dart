// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/generated/assets.gen.dart';

class ToolbarSendButton extends StatelessWidget {
  const ToolbarSendButton({
    required this.onPressed,
    this.enabled = false,
    this.loading = false,
    super.key,
  });

  final VoidCallback onPressed;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    Logger.talker?.debug(
      '[ToolbarSendButton] build() - enabled: $enabled, loading: $loading',
    );

    final canTap = enabled && !loading;
    Logger.talker
        ?.debug('[ToolbarSendButton] canTap: $canTap (enabled: $enabled && !loading: ${!loading})');

    return GestureDetector(
      onTap: canTap
          ? () {
              Logger.talker?.debug('[ToolbarSendButton] Tap received - calling onPressed');
              try {
                onPressed();
                Logger.talker?.debug('[ToolbarSendButton] onPressed completed');
              } catch (e, st) {
                Logger.error(
                  e,
                  stackTrace: st,
                  message: '[ToolbarSendButton] Error in onPressed callback',
                );
              }
            }
          : () {
              Logger.talker?.debug(
                '[ToolbarSendButton] Tap received but IGNORED - enabled: $enabled, loading: $loading',
              );
            },
      child: Container(
        width: 48.0.s,
        height: 28.0.s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0.s),
          color:
              enabled ? context.theme.appColors.primaryAccent : context.theme.appColors.sheetLine,
        ),
        alignment: Alignment.center,
        child: loading
            ? const IONLoadingIndicator()
            : Assets.svg.iconFeedSendbutton.icon(size: 20.0.s),
      ),
    );
  }
}
