// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu_container.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/context_menu_item_divider.dart';
import 'package:ion/generated/assets.gen.dart';

enum CreatorTokensFilterType {
  allTokens,
  creatorTokens,
  contentTokens;

  String getTitle(BuildContext context) {
    switch (this) {
      case CreatorTokensFilterType.allTokens:
        return context.i18n.creator_tokens_filter_all_tokens;
      case CreatorTokensFilterType.creatorTokens:
        return context.i18n.creator_tokens_filter_creator_tokens;
      case CreatorTokensFilterType.contentTokens:
        return context.i18n.creator_tokens_filter_content_tokens;
    }
  }
}

class CreatorTokensFilterBar extends HookWidget {
  const CreatorTokensFilterBar({
    required this.selectedFilter,
    required this.onFilterChanged,
    super.key,
  });

  final CreatorTokensFilterType selectedFilter;
  final ValueChanged<CreatorTokensFilterType> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final isMenuOpen = useState(false);
    final rotationController = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );

    useEffect(
      () {
        if (isMenuOpen.value) {
          rotationController.forward();
        } else {
          rotationController.reverse();
        }
        return null;
      },
      [isMenuOpen.value],
    );

    return PinnedHeaderSliver(
      child: ColoredBox(
        color: context.theme.appColors.secondaryBackground,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0.s,
            vertical: 12.0.s,
          ),
          child: Row(
            children: [
              Assets.svg.iconFilter1.icon(
                size: 20.0.s,
                color: context.theme.appColors.tertiaryText,
              ),
              SizedBox(width: 8.0.s),
              Text(
                context.i18n.creator_tokens_filter_label,
                textAlign: TextAlign.center,
                style: context.theme.appTextThemes.subtitle3.copyWith(
                  color: context.theme.appColors.tertiaryText,
                ),
              ),
              const Spacer(),
              OverlayMenu(
                onOpen: () => isMenuOpen.value = true,
                onClose: () => isMenuOpen.value = false,
                menuBuilder: (closeMenu) {
                  final menuItems = <Widget>[
                    for (final type in CreatorTokensFilterType.values)
                      _FilterMenuItem(
                        label: type.getTitle(context),
                        isSelected: type == selectedFilter,
                        onPressed: () {
                          closeMenu();
                          onFilterChanged(type);
                        },
                      ),
                  ];
                  return OverlayMenuContainer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: menuItems.separated(const ContextMenuItemDivider()).toList(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      selectedFilter.getTitle(context),
                      textAlign: TextAlign.center,
                      style: context.theme.appTextThemes.subtitle3.copyWith(
                        color: context.theme.appColors.tertiaryText,
                        height: 1,
                      ),
                    ),
                    SizedBox(width: 4.0.s),
                    RotationTransition(
                      turns: Tween<double>(begin: 0, end: 0.5).animate(
                        CurvedAnimation(
                          parent: rotationController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Assets.svg.iconArrowDown.icon(
                        size: 16.0.s,
                        color: context.theme.appColors.tertiaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterMenuItem extends StatelessWidget {
  const _FilterMenuItem({
    required this.label,
    required this.onPressed,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        height: 44.0.s,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0.s),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.theme.appTextThemes.subtitle3.copyWith(
                    color: context.theme.appColors.primaryText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
