// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/feed_interests.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class ArticleCategoriesRow extends StatelessWidget {
  const ArticleCategoriesRow({
    required this.items,
    required this.selectedItems,
    required this.onToggle,
    super.key,
    this.showAddButton = false,
  });

  final List<MapEntry<String, FeedInterestsCategory>> items;
  final Set<String> selectedItems;
  final ValueChanged<String> onToggle;
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 16.0.s),
        if (showAddButton)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12.0.s),
            child: Button.icon(
              borderRadius: BorderRadius.circular(12.0.s),
              borderColor: colors.onTertiaryFill,
              size: 40.0.s,
              type: ButtonType.secondary,
              icon: Assets.svg.iconPlusCreatechannel.icon(
                color: colors.primaryAccent,
                size: 28.0.s,
              ),
              onPressed: () => FeedVisibleArticleCategoriesRoute().push<void>(context),
            ),
          ),
        ...items.map(
          (item) => Padding(
            padding: EdgeInsetsDirectional.only(end: 12.0.s),
            child: _CategoryButton(
              categoryKey: item.key,
              category: item.value,
              isSelected: selectedItems.contains(item.key),
              onToggle: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.categoryKey,
    required this.category,
    required this.isSelected,
    required this.onToggle,
  });

  final String categoryKey;
  final FeedInterestsCategory category;
  final bool isSelected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return Button.compact(
      backgroundColor: colors.tertiaryBackground,
      type: ButtonType.outlined,
      leadingIconOffset: 6.0.s,
      leadingIcon: NetworkIconWidget(
        imageUrl: category.iconUrl ?? '',
        color: isSelected ? colors.primaryAccent : colors.tertiaryText,
        type: WalletItemIconType.medium(),
      ),
      label: Text(
        category.display,
        style: context.theme.appTextThemes.caption.copyWith(
          color: isSelected ? colors.primaryAccent : colors.tertiaryText,
        ),
      ),
      onPressed: () => onToggle(categoryKey),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: 10.0.s,
          vertical: 8.0.s,
        ),
        side: BorderSide(
          color: isSelected ? colors.primaryAccent : colors.onTertiaryFill,
        ),
      ),
    );
  }
}
