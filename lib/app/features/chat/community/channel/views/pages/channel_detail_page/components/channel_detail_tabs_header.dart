// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/channel/models/channel_detail_tab.dart';

class ChannelDetailTabsHeader extends ConsumerWidget {
  const ChannelDetailTabsHeader({
    this.controller,
    super.key,
  });

  final TabController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBar(
      controller: controller,
      padding: EdgeInsets.symmetric(
        horizontal: 6.0.s,
      ),
      tabAlignment: TabAlignment.start,
      isScrollable: true,
      labelPadding: EdgeInsets.symmetric(horizontal: 10.0.s),
      labelColor: context.theme.appColors.primaryAccent,
      unselectedLabelColor: context.theme.appColors.tertiaryText,
      tabs: ChannelDetailTab.values.map((tabType) {
        return _TabHeaderItem(tabType: tabType);
      }).toList(),
      indicatorColor: context.theme.appColors.primaryAccent,
      dividerHeight: 0,
    );
  }
}

class _TabHeaderItem extends StatelessWidget {
  const _TabHeaderItem({
    required this.tabType,
  });

  final ChannelDetailTab tabType;

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
