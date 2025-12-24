// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_delegation_handler.r.g.dart';

class UserDelegationHandler extends GlobalSubscriptionEventHandler {
  UserDelegationHandler(this.ionConnectCache);

  final IonConnectCache ionConnectCache;

  @override
  bool canHandle(EventMessage eventMessage) {
    return eventMessage.kind == UserDelegationEntity.kind;
  }

  @override
  Future<void> handle(EventMessage eventMessage) async {
    final entity = UserDelegationEntity.fromEventMessage(eventMessage);
    await ionConnectCache.cache(entity);
  }
}

@riverpod
UserDelegationHandler userDelegationHandler(Ref ref) {
  final cache = ref.read(ionConnectCacheProvider.notifier);

  return UserDelegationHandler(cache);
}
