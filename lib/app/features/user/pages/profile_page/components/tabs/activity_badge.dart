// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class ActivityBadge extends StatelessWidget {
  const ActivityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16.s, top: 8.s),
      child: Row(
        children: [
          Assets.svg.iconoirCoinsSwap.icon(size: 16.0.s),
          SizedBox(width: 6.0.s),
          Text(
            // TODO(Slava): add translation
            'Activity',
            textAlign: TextAlign.center,
            style: context.theme.appTextThemes.subtitle3.copyWith(
              color: context.theme.appColors.onTertiaryBackground,
            ),
          ),
        ],
      ),
    );
  }
}
