// SPDX-License-Identifier: ice License 1.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'initial_notification_provider.r.g.dart';

@Riverpod(keepAlive: true)
class InitialNotification extends _$InitialNotification {
  @override
  Map<String, dynamic>? build() {
    return null;
  }

  set notification(Map<String, dynamic> data) {
    state = data;
  }

  Map<String, dynamic>? consume() {
    final notification = state;
    state = null;
    return notification;
  }
}
