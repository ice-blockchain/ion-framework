// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class RecentTopicPill extends StatelessWidget {
  const RecentTopicPill({
    required this.categoryName,
    required this.onPress,
    super.key,
  });

  final String categoryName;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(horizontal: 12.s, vertical: 8.s),
        decoration: BoxDecoration(
          color: context.theme.appColors.onPrimaryAccent,
          borderRadius: BorderRadius.circular(16.s),
          border: Border.all(
            width: 1.s,
            color: context.theme.appColors.onTertiaryFill,
          ),
        ),
        child: Text(
          categoryName,
          style: context.theme.appTextThemes.body,
        ),
      ),
    );
  }
}
