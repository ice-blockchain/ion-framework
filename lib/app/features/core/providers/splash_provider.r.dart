// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_provider.r.g.dart';

@Riverpod(keepAlive: true)
class Splash extends _$Splash {
  @override
  bool build() {
    return false;
  }

  set animationCompleted(bool completed) {
    state = completed;
  }
}

@riverpod
Future<void> splashReady(Ref ref) async {
  final currentValue = ref.read(splashProvider);
  if (currentValue) {
    return;
  }

  final completer = Completer<void>();

  ref.listen<bool>(splashProvider, (bool? previous, bool next) {
    if (next && !completer.isCompleted) {
      completer.complete();
    }
  });

  return completer.future;
}
