// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/content_creation_blocked_modal/content_creation_blocked_modal.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class FeedContentCreationBlockedModalPage extends StatelessWidget {
  const FeedContentCreationBlockedModalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetContent(
      backgroundColor: context.theme.appColors.secondaryBackground,
      topPadding: 0.0.s,
      body: const AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: ContentCreationBlockedModal(),
      ),
    );
  }
}
