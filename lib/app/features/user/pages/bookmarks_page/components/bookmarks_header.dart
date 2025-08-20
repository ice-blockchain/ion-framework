// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/generated/assets.gen.dart';

class BookmarksHeader extends StatelessWidget implements PreferredSizeWidget {
  const BookmarksHeader({
    required this.onSearchQueryUpdated,
    required this.loading,
    super.key,
  });

  final void Function(String) onSearchQueryUpdated;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NavigationAppBar.screen(
          title: Text(
            context.i18n.bookmarks_title,
            style: context.theme.appTextThemes.subtitle2,
          ),
          actions: [
            IconButton(
              padding: EdgeInsets.zero,
              icon: Assets.svg.iconEditLink.icon(
                size: NavigationAppBar.actionButtonSide,
                color: context.theme.appColors.primaryText,
              ),
              onPressed: () {
                EditBookmarksRoute().push<void>(context);
              },
            ),
          ],
        ),
        ScreenSideOffset.small(
          child: SearchInput(
            onTextChanged: onSearchQueryUpdated,
            loading: loading,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(NavigationAppBar.screenHeaderHeight + SearchInput.height);
}
