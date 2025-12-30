// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/constants/links.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/components/verify_identity/secured_by.dart';
import 'package:ion/app/services/browser/browser.dart';
import 'package:ion/l10n/i10n.dart';

enum FooterLink {
  terms,
  privacy,
  unknown;

  factory FooterLink.fromKey(String key) {
    return switch (key) {
      'privacy_policy' => FooterLink.privacy,
      'terms_of_service' => FooterLink.terms,
      _ => FooterLink.unknown
    };
  }

  VoidCallback get onPressed {
    return switch (this) {
      FooterLink.terms => () => openUrlInAppBrowser(Links.terms),
      FooterLink.privacy => () => openUrlInAppBrowser(Links.privacy),
      _ => () {},
    };
  }

  String label(BuildContext context) {
    return switch (this) {
      FooterLink.terms => context.i18n.auth_terms_of_service,
      FooterLink.privacy => context.i18n.auth_privacy_policy,
      _ => ''
    };
  }
}

class AuthFooter extends HookWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final termsPrivacyTextSpan = useMemoized(
      () => replaceString(
        context.i18n.auth_privacy,
        tagRegex('link', isSingular: false),
        (match, int index) {
          final link = FooterLink.fromKey(match.namedGroup('link')!);
          return TextSpan(
            text: link.label(context),
            style: context.theme.appTextThemes.caption3.copyWith(
              color: context.theme.appColors.primaryAccent,
            ),
            recognizer: TapGestureRecognizer()..onTap = link.onPressed,
          );
        },
      ),
    );

    return Column(
      children: [
        const SecuredBy(),
        SizedBox(height: 20.0.s),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 220.0.s),
          child: Text.rich(
            termsPrivacyTextSpan,
            textAlign: TextAlign.center,
            style: context.theme.appTextThemes.caption3.copyWith(
              color: context.theme.appColors.tertiaryText,
            ),
          ),
        ),
      ],
    );
  }
}
