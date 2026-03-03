// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';

class UiEventQueueListener extends HookConsumerWidget {
  const UiEventQueueListener({
    super.key,
  });

  void _processQueue(WidgetRef ref) {
    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _processQueue(ref));
      return;
    }

    ref.read(uiEventQueueNotifierProvider.notifier).processQueue(
      (event) async {
        await event.performAction(navigatorContext);
      },
    ).then((_) {
      final state = ref.read(uiEventQueueNotifierProvider);
      if (state.isNotEmpty) {
        SchedulerBinding.instance.addPostFrameCallback((_) => _processQueue(ref));
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiEvents = ref.watch(uiEventQueueNotifierProvider);

    useOnInit(
      () => _processQueue(ref),
      uiEvents.toList(),
    );

    return const SizedBox.shrink();
  }
}
