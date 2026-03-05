// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';

class CountrySearchHeader extends StatelessWidget {
  const CountrySearchHeader({
    required this.isLoading,
    required this.onTextChanged,
    required this.onCancelSearch,
    super.key,
  });

  final bool isLoading;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onCancelSearch;

  @override
  Widget build(BuildContext context) {
    return PinnedHeaderSliver(
      child: ColoredBox(
        color: context.theme.appColors.onPrimaryAccent,
        child: Column(
          children: [
            SizedBox(height: 16.0.s),
            ScreenSideOffset.small(
              child: SearchInput(
                restorationId: 'country_search_input',
                loading: isLoading,
                onTextChanged: onTextChanged,
                onCancelSearch: onCancelSearch,
              ),
            ),
            SizedBox(height: 16.0.s),
          ],
        ),
      ),
    );
  }
}
