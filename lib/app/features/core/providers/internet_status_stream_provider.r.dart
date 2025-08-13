// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/core/providers/internet_connection_checker_provider.r.dart';
import 'package:ion/app/features/core/services/internet_connection_checker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'internet_status_stream_provider.r.g.dart';

@Riverpod(keepAlive: true)
Stream<InternetStatus> internetStatusStream(Ref ref) async* {
  final lifecycleState = ref.watch(appLifecycleProvider);
  if (lifecycleState != AppLifecycleState.resumed) {
    yield InternetStatus.connected;
    return;
  }
  yield* ref.watch(internetConnectionCheckerProvider).onStatusChange;
}

@riverpod
bool hasInternetConnection(Ref ref) {
  final status = ref.watch(internetStatusStreamProvider).valueOrNull;
  return status != InternetStatus.disconnected;
}
