// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class ContentCreationBlockedModal extends HookConsumerWidget {
  const ContentCreationBlockedModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyles = context.theme.appTextThemes;
    final colors = context.theme.appColors;
    final locale = context.i18n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScreenSideOffset.medium(
          child: Column(
            children: [
              SizedBox(height: 24.s),
              Assets.svg.walleticonwalletemptypost.icon(size: 80.s),
              SizedBox(height: 10.s),
              Text(
                //
                locale.feed_content_creation_blocked_title,
                style: textStyles.title,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.s),
              Text(
                locale.feed_content_creation_blocked_description,
                style: textStyles.body2.copyWith(color: colors.secondaryText),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.s),
              Button(
                minimumSize: Size(double.infinity, 56.s),
                label: Text(locale.button_try_again),
                leadingIcon: Assets.svg.iconbuttonTryagain.icon(size: 24.s),
                onPressed: () {
                  invalidateCurrentUserMetadataProviders(ref);
                },
              ),
            ],
          ),
        ),
        ScreenBottomOffset(),
      ],
    );
  }
}
