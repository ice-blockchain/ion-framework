// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/providers/feed_config_provider.r.dart';
import 'package:ion/app/utils/queue.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_request_queue.r.g.dart';

@Riverpod(keepAlive: true)
Future<ConcurrentTasksQueue> feedRequestQueue(Ref ref) async {
  final feedConfig = await ref.read(feedConfigProvider.future);
  final queue = ConcurrentTasksQueue(maxConcurrent: feedConfig.concurrentRequests);
  onLogout(ref, queue.cancelAll);
  onUserSwitch(ref, queue.cancelAll);
  return queue;
}
