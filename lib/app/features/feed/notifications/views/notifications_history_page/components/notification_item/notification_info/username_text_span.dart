// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

TextSpan buildUsernameTextSpan(
  BuildContext context, {
  required String displayName,
  required TapGestureRecognizer recognizer,
}) {
  return TextSpan(
    text: displayName,
    style: context.theme.appTextThemes.body.copyWith(
      color: context.theme.appColors.primaryText,
    ),
    recognizer: recognizer,
  );
}
