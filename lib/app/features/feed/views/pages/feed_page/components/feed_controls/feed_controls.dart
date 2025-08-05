// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/feed_controls/components/feed_navigation/feed_navigation.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/feed_controls/components/feed_navigation/feed_notifications_button.dart';
import 'package:ion/app/router/components/navigation_button/navigation_button.dart';

class FeedControls extends StatelessWidget {
  const FeedControls({
    super.key,
  });

  static double get height => NavigationButton.defaultSize + FeedNotificationsButton.counterOffset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const FeedNavigation(),
    );
  }
}
