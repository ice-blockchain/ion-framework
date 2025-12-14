// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';

class CreatorTokensSearchBar extends StatelessWidget {
  const CreatorTokensSearchBar({
    required this.isVisible,
    required this.searchController,
    required this.searchFocusNode,
    required this.onCancelSearch,
    super.key,
  });

  final bool isVisible;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onCancelSearch;

  @override
  Widget build(BuildContext context) {
    return PinnedHeaderSliver(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: isVisible
            ? ColoredBox(
                color: context.theme.appColors.onPrimaryAccent,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    top: 12.0.s,
                    bottom: 8.0.s,
                  ),
                  child: ScreenSideOffset.small(
                    child: SearchInput(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      onCancelSearch: onCancelSearch,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
