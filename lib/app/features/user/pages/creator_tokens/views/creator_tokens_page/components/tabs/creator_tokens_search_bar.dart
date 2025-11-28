// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';

class CreatorTokensSearchBar extends StatelessWidget {
  const CreatorTokensSearchBar({
    required this.controller,
    required this.loading,
    required this.onTextChanged,
    required this.onCancelSearch,
    super.key,
  });

  final TextEditingController controller;
  final bool loading;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onCancelSearch;

  @override
  Widget build(BuildContext context) {
    return PinnedHeaderSliver(
      child: ColoredBox(
        color: context.theme.appColors.onPrimaryAccent,
        child: Padding(
          padding: EdgeInsetsDirectional.only(top: 12.s, bottom: 8.s),
          child: ScreenSideOffset.small(
            child: SearchInput(
              controller: controller,
              loading: loading,
              onTextChanged: onTextChanged,
              onCancelSearch: onCancelSearch,
            ),
          ),
        ),
      ),
    );
  }
}
