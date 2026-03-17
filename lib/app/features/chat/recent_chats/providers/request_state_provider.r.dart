// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'request_state_provider.r.g.dart';

@riverpod
class RequestState extends _$RequestState {
  @override
  bool build() {
    keepAliveWhenAuthenticated(ref);

    return false;
  }

  set value(bool value) {
    state = value;
  }
}
