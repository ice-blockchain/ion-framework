// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/iterable.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';

class BottomSheetMenuContent extends StatelessWidget {
  const BottomSheetMenuContent({
    required this.groups,
    super.key,
  });

  final List<List<Widget>> groups;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0.s, 24.0.s, 16.0.s, 16.0.s),
        child: Column(
          spacing: 12.5.s,
          children: groups
              .map(
                (groupMenuItems) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.theme.appColors.tertiaryBackground,
                    borderRadius: BorderRadius.circular(16.0.s),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: groupMenuItems.separated(const HorizontalSeparator()).toList(),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
