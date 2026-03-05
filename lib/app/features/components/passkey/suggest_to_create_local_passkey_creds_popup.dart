// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/local_passkey_creds_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class SuggestToCreateLocalPasskeyCredsPopup extends HookConsumerWidget {
  const SuggestToCreateLocalPasskeyCredsPopup({
    required this.username,
    super.key,
  });

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minSize = Size(56.0.s, 56.0.s);
    final rejectToCreateLocalPasskeyCredsState =
        ref.watch(rejectToCreateLocalPasskeyCredsNotifierProvider);
    final acceptToCreateLocalPasskeyCredsState =
        ref.watch(acceptToCreateLocalPasskeyCredsNotifierProvider);

    final handleLocalPasskeyFlow = useCallback(
      (Future<void> Function() localPasskeyAction) async {
        await localPasskeyAction();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      [context],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 30.0.s, end: 30.0.s, top: 30.0.s),
          child: InfoCard(
            iconAsset: Assets.svg.actionWalletFaceid,
            title: context.i18n.new_passkey_creds_suggestion_title,
            description: context.i18n.new_passkey_creds_suggestion_desc,
          ),
        ),
        SizedBox(height: 38.0.s),
        ScreenSideOffset.small(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Button.compact(
                  type: ButtonType.outlined,
                  label: Text(context.i18n.button_skip),
                  minimumSize: minSize,
                  disabled: rejectToCreateLocalPasskeyCredsState.isLoading ||
                      acceptToCreateLocalPasskeyCredsState.isLoading,
                  trailingIcon: rejectToCreateLocalPasskeyCredsState.isLoading
                      ? const IONLoadingIndicator(
                          type: IndicatorType.dark,
                        )
                      : const SizedBox.shrink(),
                  onPressed: () => handleLocalPasskeyFlow(
                    () => ref
                        .read(rejectToCreateLocalPasskeyCredsNotifierProvider.notifier)
                        .rejectToCreateLocalPasskeyCreds(username: username),
                  ),
                ),
              ),
              SizedBox(
                width: 16.0.s,
              ),
              Expanded(
                child: Button.compact(
                  label: Text(context.i18n.button_continue),
                  minimumSize: minSize,
                  disabled: acceptToCreateLocalPasskeyCredsState.isLoading ||
                      rejectToCreateLocalPasskeyCredsState.isLoading,
                  trailingIcon: acceptToCreateLocalPasskeyCredsState.isLoading
                      ? const IONLoadingIndicator()
                      : const SizedBox.shrink(),
                  onPressed: () => handleLocalPasskeyFlow(
                    () => ref
                        .read(acceptToCreateLocalPasskeyCredsNotifierProvider.notifier)
                        .createLocalPasskeyCreds(username: username),
                  ),
                ),
              ),
            ],
          ),
        ),
        const ScreenBottomOffset(),
      ],
    );
  }
}
