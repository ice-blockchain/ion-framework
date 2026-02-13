// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';

class CancelRecordButton extends ConsumerWidget {
  const CancelRecordButton({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 16.0.s),
      child: GestureDetector(
        onTap: onPressed,
        child: Text(
          context.i18n.button_cancel,
          style: context.theme.appTextThemes.body2.copyWith(
            color: context.theme.appColors.primaryAccent,
          ),
        ),
      ),
    );
  }
}
