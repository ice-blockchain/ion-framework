// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';

class BottomSheetMenuHeaderButton extends StatelessWidget {
  const BottomSheetMenuHeaderButton({
    required this.label,
    required this.iconAsset,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String iconAsset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.0.s, horizontal: 16.0.s),
        decoration: BoxDecoration(
          color: context.theme.appColors.primaryAccent,
          borderRadius: BorderRadius.circular(16.0.s),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconAsset.icon(
              size: 20.0.s,
              color: context.theme.appColors.onPrimaryAccent,
            ),
            SizedBox(height: 8.0.s),
            Text(
              label,
              style: context.theme.appTextThemes.subtitle2.copyWith(
                color: context.theme.appColors.onPrimaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
