// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/components/navigation_button/navigation_button.dart';
import 'package:ion/generated/assets.gen.dart';

class AdvancedSearchNavigation extends HookConsumerWidget {
  const AdvancedSearchNavigation({
    required this.query,
    required this.onTapSearch,
    this.onFiltersPressed,
    super.key,
  });

  final String query;

  final ValueSetter<String> onTapSearch;

  final VoidCallback? onFiltersPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();

    useOnInit(
      () {
        searchController.text = query;
      },
      [query],
    );

    return ScreenSideOffset.small(
      child: Row(
        children: [
          NavigationButton(
            onPressed: context.pop,
            icon: Assets.svg.iconBackArrow.icon(
              color: context.theme.appColors.primaryText,
              flipForRtl: true,
            ),
          ),
          SizedBox(width: 12.0.s),
          Expanded(
            child: SearchInput(
              restorationId: 'advanced_search_search_input',
              controller: searchController,
              onTap: onTapSearch,
            ),
          ),
          SizedBox(width: 12.0.s),
          if (onFiltersPressed != null)
            NavigationButton(
              onPressed: () {
                onFiltersPressed?.call();
              },
              icon: Assets.svg.iconButtonManagecoin.icon(
                color: context.theme.appColors.primaryText,
              ),
            ),
        ],
      ),
    );
  }
}
