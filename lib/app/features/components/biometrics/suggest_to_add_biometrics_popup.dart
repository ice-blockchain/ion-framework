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
import 'package:ion/app/features/user/providers/biometrics_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class SuggestToAddBiometricsPopup extends HookConsumerWidget {
  const SuggestToAddBiometricsPopup({
    required this.username,
    required this.password,
    super.key,
  });

  final String username;
  final String password;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minSize = Size(56.0.s, 56.0.s);
    final rejectToUseBiometricsState = ref.watch(rejectToUseBiometricsNotifierProvider);
    final enrollToUseBiometricsState = ref.watch(enrollToUseBiometricsNotifierProvider);

    final handleBiometricsFlow = useCallback(
      (Future<void> Function() biometricsAction) async {
        await biometricsAction();
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
            title: context.i18n.biometrics_suggestion_title,
            description: context.i18n.biometrics_suggestion_desc,
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
                  label: Text(context.i18n.button_cancel),
                  minimumSize: minSize,
                  disabled:
                      rejectToUseBiometricsState.isLoading || enrollToUseBiometricsState.isLoading,
                  trailingIcon: rejectToUseBiometricsState.isLoading
                      ? const IONLoadingIndicator(
                          type: IndicatorType.dark,
                        )
                      : const SizedBox.shrink(),
                  onPressed: () => handleBiometricsFlow(
                    () => ref
                        .read(rejectToUseBiometricsNotifierProvider.notifier)
                        .rejectToUseBiometrics(
                          username: username,
                          password: password,
                        ),
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
                  disabled:
                      enrollToUseBiometricsState.isLoading || rejectToUseBiometricsState.isLoading,
                  trailingIcon: enrollToUseBiometricsState.isLoading
                      ? const IONLoadingIndicator()
                      : const SizedBox.shrink(),
                  onPressed: () => handleBiometricsFlow(
                    () => ref
                        .read(enrollToUseBiometricsNotifierProvider.notifier)
                        .enrollToUseBiometrics(
                          username: username,
                          password: password,
                          localisedReason: context.i18n.biometrics_suggestion_title,
                        ),
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
