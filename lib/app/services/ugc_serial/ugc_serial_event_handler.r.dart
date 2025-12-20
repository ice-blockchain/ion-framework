// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/entity_label.f.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/services/ugc_serial/ugc_serial_service.r.dart';

class UgcSerialEventHandler extends GlobalSubscriptionEventHandler {
  UgcSerialEventHandler({
    required this.ugcSerialService,
    required this.currentUserPubkey,
  });

  final UgcSerialService ugcSerialService;
  final String currentUserPubkey;

  @override
  bool canHandle(EventMessage eventMessage) {
    return _ugcKinds.contains(eventMessage.kind) && eventMessage.pubkey == currentUserPubkey;
  }

  @override
  Future<void> handle(EventMessage eventMessage) async {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final ugcLabel = EntityLabel.fromTags(tags, namespace: EntityLabelNamespace.ugcSerial);

    await ugcSerialService.updateFromLabel(ugcLabel);
  }
}

final ugcSerialEventHandlerProvider = Provider<UgcSerialEventHandler?>((ref) {
  final ugcSerialService = ref.watch(currentUserUgcSerialServiceProvider);
  final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);

  if (ugcSerialService == null || currentUserPubkey == null) {
    return null;
  }

  return UgcSerialEventHandler(
    ugcSerialService: ugcSerialService,
    currentUserPubkey: currentUserPubkey,
  );
});

const _ugcKinds = [
  PostEntity.kind,
  ModifiablePostEntity.kind,
  ArticleEntity.kind,
];
