// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';

TextSpan buildUsernameTextSpan(
  BuildContext context, {
  required UserPreviewData userData,
  required TapGestureRecognizer recognizer,
}) {
  final displayName =
      userData.trimmedDisplayName.isEmpty ? userData.name : userData.trimmedDisplayName;
  return TextSpan(
    text: displayName,
    style: context.theme.appTextThemes.body.copyWith(
      color: context.theme.appColors.primaryText,
    ),
    recognizer: recognizer,
  );
}
