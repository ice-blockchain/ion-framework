// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/tabs/tab_type.dart';

class TabsHeaderTab extends StatelessWidget {
  const TabsHeaderTab({
    required this.tabType,
    super.key,
  });

  final TabType tabType;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 8.0.s),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tabType.iconAsset.icon(size: 18.0.s, color: color),
          SizedBox(width: 6.0.s),
          Text(
            tabType.getTitle(context),
            style: context.theme.appTextThemes.subtitle3.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
