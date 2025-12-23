// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';

class DeeplinkNavigateEvent extends UiEvent {
  const DeeplinkNavigateEvent(this.path);

  final String path;

  @override
  void performAction(BuildContext context) {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    final router = GoRouter.maybeOf(context);
    final isMainModalOpen = router?.state.isMainModalOpen ?? false;

    if (isMainModalOpen || context.canPop()) {
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    }

    if (path == FeedRoute().location ||
        path == ChatRoute().location ||
        path == WalletRoute().location ||
        path == SelfProfileRoute().location) {
      GoRouter.of(context).go(path);
    } else {
      GoRouter.of(context).push(path);
    }
  }
}
