// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class ChatLearnMoreModal extends ConsumerWidget {
  const ChatLearnMoreModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetContent(
      topPadding: 0,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            title: Text(context.i18n.common_information),
            actions: const [NavigationCloseButton()],
          ),
          ScreenSideOffset.medium(
            child: Padding(
              padding: EdgeInsetsDirectional.only(top: 13.0.s, bottom: 16.0.s),
              child: Column(
                children: [
                  Assets.svg.walletIconChatEncription.icon(size: 80.0.s),
                  SizedBox(height: 10.0.s),
                  Text(
                    context.i18n.chat_learn_more_modal_title,
                    style: context.theme.appTextThemes.title,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.0.s),
                  Text(
                    context.i18n.chat_learn_more_modal_description,
                    style: context.theme.appTextThemes.body2.copyWith(
                      color: context.theme.appColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const ScreenBottomOffset(),
        ],
      ),
    );
  }
}
