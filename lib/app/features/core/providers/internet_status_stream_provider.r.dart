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

  /// We follow the app lifecycle here cause if we don't,
  /// after user will hide app after some time we will disconnect the internet
  /// and after user will see no internet connection in the app error
  ///
  /// So, to avoid this we follow the app lifecycle here
  if (lifecycleState != AppLifecycleState.resumed) {
    final previousStatus = ref.read(internetStatusStreamProvider).valueOrNull;

    if (previousStatus == InternetStatus.connected) {
      yield InternetStatus.pausedAfterConnected;
    } else if (previousStatus == InternetStatus.disconnected) {
      yield InternetStatus.pausedAfterDisconnected;
    }

    return;
  }
  yield* ref.watch(internetConnectionCheckerProvider).onStatusChange;
}

@riverpod
bool hasInternetConnection(Ref ref) {
  final status = ref.watch(internetStatusStreamProvider).valueOrNull;
  return status != InternetStatus.disconnected && status != InternetStatus.pausedAfterDisconnected;
}
