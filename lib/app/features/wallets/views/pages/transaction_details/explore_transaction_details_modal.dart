// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/web_view.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class ExploreTransactionDetailsModal extends HookConsumerWidget {
  const ExploreTransactionDetailsModal({
    required this.url,
    super.key,
  });

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetContent(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          PinnedHeaderSliver(
            child: NavigationAppBar.modal(
              title: Text(context.i18n.wallet_explore_transaction_details_title),
              actions: const [NavigationCloseButton()],
            ),
          ),
          SliverFillRemaining(
            child: WebView(url: url),
          ),
          SliverToBoxAdapter(
            child: ScreenBottomOffset(),
          ),
        ],
      ),
    );
  }
}
