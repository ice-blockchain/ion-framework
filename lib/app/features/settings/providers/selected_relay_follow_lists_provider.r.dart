// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/settings/providers/selected_relay_provider.r.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_relay_follow_lists_provider.r.g.dart';

const _logTag = '[SELECTED_RELAY_FOLLOW_LISTS]';
const _followListLimit = 10;

/// Fetches the first 10 kind 3 (follow list) events from the selected relay.
/// Returns raw EventMessage objects for inspection without parsing.
@riverpod
Future<List<EventMessage>> selectedRelayFollowLists(
  Ref ref,
) async {
  final selectedRelay = ref.watch(selectedRelayProvider);
  
  if (selectedRelay == null) {
    Logger.log('$_logTag No relay selected, returning empty list');
    return [];
  }

  Logger.log('$_logTag Fetching follow lists from selected relay: $selectedRelay');

  final requestMessage = RequestMessage();
  requestMessage.addFilter(
    RequestFilter(
      kinds: const [FollowListEntity.kind],
      limit: _followListLimit,
    ),
  );

  final actionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  
  final events = await ref
      .read(ionConnectNotifierProvider.notifier)
      .requestEvents(
        requestMessage,
        actionSource: actionSource,
      )
      .take(_followListLimit)
      .toList();

  Logger.log('$_logTag Fetched ${events.length} events from $selectedRelay');
  
  // Log event details for debugging
  for (final event in events) {
    Logger.log(
      '$_logTag Event: id=${event.id}, pubkey=${event.pubkey}, tags=${event.tags}',
    );
  }
  
  return events;
}

