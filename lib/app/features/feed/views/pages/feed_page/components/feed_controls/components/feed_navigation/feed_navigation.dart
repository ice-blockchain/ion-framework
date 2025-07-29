// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/feed_controls/components/feed_filters/feed_filters_menu_button.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/feed_controls/components/feed_navigation/feed_notifications_button.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class FeedNavigation extends StatelessWidget {
  const FeedNavigation({
    this.scrollController,
    super.key,
  });

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(top: FeedNotificationsButton.counterOffset),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FeedSimpleSearchRoute().push<void>(context),
              child: const IgnorePointer(child: SearchInput()),
            ),
          ),
          SizedBox(width: 12.0.s),
          const FeedNotificationsButton(),
          SizedBox(width: 12.0.s),
          FeedFiltersMenuButton(scrollController: scrollController),
        ],
      ),
    );
  }
}
