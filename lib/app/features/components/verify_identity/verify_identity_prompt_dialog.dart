// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/secured_by.dart';
import 'package:ion/app/features/core/providers/theme_mode_provider.r.dart';
import 'package:ion/app/features/user/providers/user_verify_identity_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class VerifyIdentityPromptDialog extends ConsumerWidget {
  const VerifyIdentityPromptDialog({
    this.identityKeyName,
    super.key,
  });

  final String? identityKeyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textThemes = context.theme.appTextThemes;
    final isThemeLight = ref.watch(appThemeModeProvider) == ThemeMode.light;

    final verifyIdentityType = ref
        .watch(
          verifyIdentityTypeProvider(identityKeyName: identityKeyName),
        )
        .valueOrNull;

    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    if (verifyIdentityType == null) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: ScreenSideOffset.defaultMediumMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 65.0.s),
            Assets.svg.actionWalletPasskey.icon(size: 80.0.s),
            SizedBox(height: 20.0.s),
            Text(
              verifyIdentityType.getTitle(context),
              textAlign: TextAlign.center,
              style: textThemes.headline1,
            ),
            SizedBox(height: 8.0.s),
            Text(
              verifyIdentityType.getDesc(context),
              textAlign: TextAlign.center,
              style: textThemes.body2.copyWith(color: colors.tertiaryText),
            ),
            SizedBox(height: 69.0.s),
            IONLoadingIndicator(
              size: Size.square(30.0.s),
              type: isThemeLight ? IndicatorType.dark : IndicatorType.light,
            ),
            const Spacer(),
            const ScreenBottomOffset(
              child: SecuredBy(),
            ),
          ],
        ),
      ),
    );
  }
}
