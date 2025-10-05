// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_event_handler.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/model/badges/badge_award.f.dart';
import 'package:ion/app/features/user/model/badges/badge_definition.f.dart';
import 'package:ion/app/features/user/model/badges/profile_badges.f.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/app/features/user/providers/service_pubkeys_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'badge_award_handler.r.g.dart';

class BadgeAwardHandler extends GlobalSubscriptionEventHandler {
  BadgeAwardHandler(this.ref);

  final Ref ref;

  @override
  bool canHandle(EventMessage eventMessage) {
    return eventMessage.kind == BadgeAwardEntity.kind;
  }

  @override
  Future<void> handle(EventMessage eventMessage) async {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);

    if (currentPubkey == null) {
      return;
    }

    final isVerified = ref.read(isUserVerifiedProvider(currentPubkey));

    if (isVerified) {
      return;
    }

    final badgeAwardEntity = BadgeAwardEntity.fromEventMessage(eventMessage);

    final pubkeys = await ref.watch(servicePubkeysProvider.future);
    final eventRef = badgeAwardEntity.data.badgeDefinitionRef;
    if (eventRef.kind == BadgeDefinitionEntity.kind &&
        eventRef.dTag == BadgeDefinitionEntity.verifiedBadgeDTag &&
        (pubkeys.isEmpty || pubkeys.contains(eventRef.masterPubkey))) {
      final badgeEntries = [
        BadgeEntry(
          definitionRef: badgeAwardEntity.data.badgeDefinitionRef,
          awardId: badgeAwardEntity.id,
        ),
      ];

      final updatedData = await ref.read(
        updatedProfileBadgesProvider(
          badgeEntries,
          currentPubkey,
        ).future,
      );

      await ref.read(ionConnectNotifierProvider.notifier).sendEntitiesData([updatedData]);

      final userMetadata = await ref.watch(userMetadataProvider(currentPubkey).future);

      if (userMetadata != null) {
        await ref
            .read(ionConnectDatabaseCacheProvider.notifier)
            .remove(userMetadata.toEventReference().toString());
        await ref
            .read(userMetadataInvalidatorNotifierProvider.notifier)
            .invalidateCurrentUserMetadataProviders();
      }
    }
  }
}

@riverpod
BadgeAwardHandler badgeAwardHandler(Ref ref) {
  return BadgeAwardHandler(ref);
}
