// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/model/feed_search_source.dart';
import 'package:ion/generated/assets.gen.dart';

class FeedSearchFilterSourceSection extends StatelessWidget {
  const FeedSearchFilterSourceSection({
    required this.selectedFilter,
    required this.onFilterChange,
    super.key,
  });

  final FeedSearchSource selectedFilter;

  final void Function(FeedSearchSource) onFilterChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.i18n.feed_search_filter_people,
          style: context.theme.appTextThemes.caption.copyWith(
            color: context.theme.appColors.quaternaryText,
          ),
        ),
        SizedBox(height: 4.0.s),
        ...FeedSearchSource.values.map<Widget>((filter) {
          return ListItem(
            onTap: () {
              onFilterChange(filter);
            },
            leading: Container(
              width: 36.0.s,
              height: 36.0.s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10.0.s)),
                border: Border.all(
                  width: 1.0.s,
                  color: context.theme.appColors.onTertiaryFill,
                ),
              ),
              child: filter.getIcon(context).icon(color: context.theme.appColors.primaryAccent),
            ),
            trailing: selectedFilter == filter
                ? Assets.svg.iconBlockCheckboxOn.icon(color: context.theme.appColors.success)
                : Assets.svg.iconblockRadiooff.icon(color: context.theme.appColors.tertiaryText),
            title: Text(filter.getLabel(context)),
            backgroundColor: context.theme.appColors.secondaryBackground,
            contentPadding: EdgeInsets.zero,
          );
        }).separated(const HorizontalSeparator()),
      ],
    );
  }
}
