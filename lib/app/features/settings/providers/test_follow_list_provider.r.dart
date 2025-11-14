// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/settings/providers/selected_relay_provider.r.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'test_follow_list_provider.r.g.dart';

const _logTag = '[TEST_FOLLOW_LIST]';

/// Tests NIP-02 compatibility by:
/// 1. Creating a follow list event with a test followee
/// 2. Sending it to the selected relay
/// 3. Fetching it back to verify it was stored correctly
@riverpod
Future<EventMessage?> testFollowListOnSelectedRelay(
  Ref ref,
  String followPubkey, // The pubkey to follow
) async {
  final selectedRelay = ref.read(selectedRelayProvider);
  if (selectedRelay == null) {
    Logger.warning('$_logTag No relay selected');
    throw Exception('No relay selected');
  }

  final currentUserPubkey = ref.read(currentPubkeySelectorProvider);
  if (currentUserPubkey == null) {
    Logger.warning('$_logTag User not authenticated');
    throw Exception('User not authenticated');
  }

  Logger.log('$_logTag Starting test: following $followPubkey on $selectedRelay');

  // 1. Get current user's follow list
  final currentFollowList = await ref.read(currentUserFollowListProvider.future);

  // 2. Create updated follow list with new followee
  final followees = Set<Followee>.from(currentFollowList?.data.list ?? []);
  
  // Don't add if already following
  if (followees.any((f) => f.pubkey == followPubkey)) {
    Logger.log('$_logTag Already following $followPubkey, removing first');
    followees.removeWhere((f) => f.pubkey == followPubkey);
  }
  
  followees.add(Followee(pubkey: followPubkey));

  final updatedFollowListData = FollowListData(list: followees.toList());

  // 3. Sign the event
  final nowBeforeSign = DateTime.now();
  Logger.log(
    '$_logTag Before sign - DateTime.now(): $nowBeforeSign',
  );
  Logger.log(
    '$_logTag Before sign - millisecondsSinceEpoch: ${nowBeforeSign.millisecondsSinceEpoch}',
  );
  Logger.log(
    '$_logTag Before sign - microsecondsSinceEpoch: ${nowBeforeSign.microsecondsSinceEpoch}',
  );
  Logger.log(
    '$_logTag Before sign - UTC: ${nowBeforeSign.toUtc()}',
  );
  Logger.log(
    '$_logTag Before sign - Local: ${nowBeforeSign.toLocal()}',
  );

  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);
  final signedEvent = await ionNotifier.sign(updatedFollowListData, useSecp256k1Schnorr: true);

  Logger.log(
    '$_logTag After sign - Event createdAt: ${signedEvent.createdAt}',
  );
  Logger.log(
    '$_logTag After sign - Event createdAt as DateTime: ${DateTime.fromMicrosecondsSinceEpoch(signedEvent.createdAt)}',
  );
  Logger.log(
    '$_logTag After sign - Event createdAt UTC: ${DateTime.fromMicrosecondsSinceEpoch(signedEvent.createdAt).toUtc()}',
  );

  Logger.log('$_logTag Created signed event: ${signedEvent.id}');

  // 4. Send to selected relay
  final actionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  await ionNotifier.sendEvent(
    signedEvent,
    actionSource: actionSource,
    cache: false, // Don't cache for testing
  );

  Logger.log('$_logTag Sent follow list event ${signedEvent.id} to $selectedRelay');

  // 5. Wait a bit for relay to process
  await Future<void>.delayed(const Duration(seconds: 2));

  // 6. Fetch it back from the selected relay
  final requestMessage = RequestMessage();
  requestMessage.addFilter(
    RequestFilter(
      kinds: const [FollowListEntity.kind],
      authors: [currentUserPubkey],
      limit: 1,
    ),
  );

  final fetchActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  final events = await ionNotifier
      .requestEvents(requestMessage, actionSource: fetchActionSource)
      .take(1)
      .toList();

  if (events.isEmpty) {
    Logger.warning('$_logTag Could not fetch back the event from $selectedRelay');
    return null;
  }

  final fetchedEvent = events.first;
  Logger.log(
    '$_logTag Successfully fetched event ${fetchedEvent.id} from $selectedRelay. '
    'Tags: ${fetchedEvent.tags}',
  );

  return fetchedEvent;
}

