// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';

class FollowSearchBar extends StatelessWidget {
  const FollowSearchBar({super.key, this.onTextChanged});

  final void Function(String)? onTextChanged;

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
                restorationId: 'follow_list_search_input',
                onTextChanged: onTextChanged,
              ),
            ),
            SizedBox(height: 8.0.s),
          ],
        ),
      ),
    );
  }
}
