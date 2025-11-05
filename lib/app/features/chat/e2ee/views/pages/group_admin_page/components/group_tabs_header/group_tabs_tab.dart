// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/group_admin_tab.dart';

class GroupTabsTab extends StatelessWidget {
  const GroupTabsTab({
    required this.tabType,
    super.key,
  });

  final GroupAdminTab tabType;

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
