// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_encrypted_event_message_handler.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/user_mute/model/database/user_mute_database.m.dart';
import 'package:ion/app/features/user_mute/model/entities/user_mute_entity.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'encrypted_user_mute_handler.r.g.dart';

class EncryptedUserMuteHandler extends GlobalSubscriptionEncryptedEventMessageHandler {
  EncryptedUserMuteHandler(this.userMuteEventDao);

  final UserMuteEventDao userMuteEventDao;

  @override
  bool canHandle({required IonConnectGiftWrapEntity entity}) {
    return entity.data.kinds.containsList([
      UserMuteEntity.kind.toString(),
    ]);
  }

  @override
  Future<EventReference?> handle(EventMessage rumor) async {
    final entity = UserMuteEntity.fromEventMessage(rumor);

    await userMuteEventDao.add(rumor);
    return entity.toEventReference();
  }
}

@riverpod
EncryptedUserMuteHandler encryptedUserMuteHandler(Ref ref) {
  return EncryptedUserMuteHandler(ref.watch(userMuteEventDaoProvider));
}
