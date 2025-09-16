// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/constants/emails.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/contact_support_notifier.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion/l10n/i10n.dart';

class NicknameReservedModal extends StatelessWidget {
  const NicknameReservedModal({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            title: Text(context.i18n.common_information),
            actions: const [NavigationCloseButton()],
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(start: 30.0.s, end: 30.0.s, top: 30.0.s),
            child: InfoCard(
              title: context.i18n.error_nickname_reserved_title,
              descriptionWidget: const _NicknameReservedDescription(),
              iconAsset: Assets.svg.actionLoginNamereserved,
            ),
          ),
          ScreenBottomOffset(),
        ],
      ),
    );
  }
}

class _NicknameReservedDescription extends HookConsumerWidget {
  const _NicknameReservedDescription();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nicknameReservedTextSpan = useMemoized(
      () => replaceString(
        context.i18n.error_nickname_reserved_description,
        tagRegex('email'),
        (String text, int index) {
          return TextSpan(
            text: Emails.support,
            style: context.theme.appTextThemes.body2.copyWith(
              color: context.theme.appColors.primaryAccent,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => ref
                  .read(contactSupportNotifierProvider.notifier)
                  .email(subject: ContactSupportSubject.reservedNickname),
          );
        },
      ),
    );

    return Text.rich(
      nicknameReservedTextSpan,
      textAlign: TextAlign.center,
      style: context.theme.appTextThemes.body2.copyWith(
        color: context.theme.appColors.secondaryText,
      ),
    );
  }
}
