// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class ProfileTokenPrice extends StatelessWidget {
  const ProfileTokenPrice({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 37.0.s,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: ShapeDecoration(
        color: context.theme.appColors.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0.s),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              r'$0,15',
              textAlign: TextAlign.center,
              style: context.theme.appTextThemes.caption3.copyWith(
                color: context.theme.appColors.primaryText,
                fontFamily: 'Noto Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
