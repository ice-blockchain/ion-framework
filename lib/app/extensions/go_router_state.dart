// SPDX-License-Identifier: ice License 1.0

import 'package:go_router/go_router.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/main_tabs/components/tab_item.dart';

extension GoRouterStateExtension on GoRouterState {
  bool get isMainModalOpen =>
      uri.toString().split('/').lastOrNull?.startsWith(AppRoutes.mainModalPath) ?? false;
  bool get shouldHideBottomBar => fullPath?.contains('fullstack') ?? false;

  TabItem get currentTab {
    return switch (matchedLocation) {
      final path when path.startsWith(FeedRoute().location) => TabItem.feed,
      final path when path.startsWith(ChatRoute().location) => TabItem.chat,
      final path when path.startsWith(WalletRoute().location) => TabItem.wallet,
      final path when path.startsWith(SelfProfileRoute().location) => TabItem.profile,
      _ => TabItem.main,
    };
  }
}
