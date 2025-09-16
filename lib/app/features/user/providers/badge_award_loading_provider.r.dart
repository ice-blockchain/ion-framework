// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'badge_award_loading_provider.r.g.dart';

@riverpod
bool isBadgeAwardValidOrLoading(
  Ref ref,
  String eventId,
  List<String> servicePubkeys,
) {
  if (servicePubkeys.isEmpty) {
    return true;
  }

  final cachedAward = ref.watch(cachedBadgeAwardProvider(eventId, servicePubkeys));
  if (cachedAward != null) {
    return true;
  }

  final loadingStates = servicePubkeys.map((pubkey) {
    return ref.watch(
      ionConnectNetworkEntityProvider(
        eventReference: ImmutableEventReference(
          masterPubkey: pubkey,
          eventId: eventId,
        ),
        actionSource: const ActionSourceCurrentUser(),
      ).select((asyncValue) => asyncValue.isLoading),
    );
  }).toList();

  return loadingStates.any((isLoading) => isLoading);
}
