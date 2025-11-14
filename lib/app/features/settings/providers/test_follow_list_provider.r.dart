// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/settings/model/available_relays.dart';
import 'package:ion/app/features/settings/providers/selected_relay_provider.r.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'test_follow_list_provider.r.g.dart';

const _logTag = '[TEST_FOLLOW_LIST]';

/// Report class for follow list test results
class FollowListTestReport {
  const FollowListTestReport({
    required this.relayUrl,
    required this.initialFollowList,
    required this.sentEvent,
    this.fetchedEvent,
    this.error,
    required this.success,
    required this.matched,
  });

  final String relayUrl;
  final FollowListEntity? initialFollowList;
  final EventMessage sentEvent;
  final EventMessage? fetchedEvent;
  final String? error;
  final bool success;
  final bool matched;

  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('=== Relay: $relayUrl ===');
    buffer.writeln('Success: $success');
    buffer.writeln('Matched: $matched');
    
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    
    buffer.writeln('\nInitial Follow List:');
    if (initialFollowList != null) {
      buffer.writeln('  ID: ${initialFollowList!.id}');
      buffer.writeln('  Followees: ${initialFollowList!.data.list.length}');
      buffer.writeln('  Followee pubkeys: ${initialFollowList!.data.list.map((f) => f.pubkey).join(", ")}');
    } else {
      buffer.writeln('  None (empty list)');
    }
    
    buffer.writeln('\nSent Event:');
    buffer.writeln('  ID: ${sentEvent.id}');
    buffer.writeln('  Pubkey: ${sentEvent.pubkey}');
    buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(sentEvent.createdAt * 1000)}');
    buffer.writeln('  Tags: ${sentEvent.tags}');
    buffer.writeln('  Signature: ${sentEvent.sig?.substring(0, 16)}...');
    
    buffer.writeln('\nFetched Event:');
    if (fetchedEvent != null) {
      buffer.writeln('  ID: ${fetchedEvent!.id}');
      buffer.writeln('  Pubkey: ${fetchedEvent!.pubkey}');
      buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(fetchedEvent!.createdAt * 1000)}');
      buffer.writeln('  Tags: ${fetchedEvent!.tags}');
      buffer.writeln('  Signature: ${fetchedEvent!.sig?.substring(0, 16)}...');
      buffer.writeln('  Match: ${fetchedEvent!.id == sentEvent.id ? "✓ IDs match" : "✗ IDs differ"}');
    } else {
      buffer.writeln('  None (not fetched)');
    }
    
    buffer.writeln('\n');
    return buffer.toString();
  }
}

/// Tests NIP-02 compatibility by:
/// 1. Creating a follow list event with current follow list
/// 2. Sending it to the selected relay
/// 3. Fetching it back to verify it was stored correctly
@riverpod
Future<EventMessage?> testFollowListOnSelectedRelay(
  Ref ref,
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

  Logger.log('$_logTag Starting test on selected relay: $selectedRelay');

  // 1. Get current user's follow list
  final currentFollowList = await ref.read(currentUserFollowListProvider.future);

  // 2. Use current follow list as-is (or create empty if none exists)
  final followListData = currentFollowList?.data ?? FollowListData(list: []);

  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);
  final signedEvent = await ionNotifier.sign(followListData, useSecp256k1Schnorr: true);

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
  // Use the pubkey from the signed event (the one that signed it)
  final requestMessage = RequestMessage();
  requestMessage.addFilter(
    RequestFilter(
      kinds: const [FollowListEntity.kind],
      authors: [signedEvent.pubkey], // Use pubkey from the signed event
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

/// Tests follow list on all popular relays one by one and returns detailed reports
@riverpod
Future<List<FollowListTestReport>> testFollowListOnAllRelays(
  Ref ref,
) async {
  final currentUserPubkey = ref.read(currentPubkeySelectorProvider);
  if (currentUserPubkey == null) {
    Logger.warning('$_logTag User not authenticated');
    throw Exception('User not authenticated');
  }

  Logger.log('$_logTag Starting test on popular relays with current follow list');

  // Get list of popular relays to test
  final relaysToTest = AvailableRelays.popularRelays;
  Logger.log('$_logTag Found ${relaysToTest.length} relays to test: ${relaysToTest.join(", ")}');

  // Get initial follow list
  final currentFollowList = await ref.read(currentUserFollowListProvider.future);
  
  final reports = <FollowListTestReport>[];
  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  // Test each relay one by one
  for (var i = 0; i < relaysToTest.length; i++) {
    final relayUrl = relaysToTest[i];
    Logger.log('$_logTag [${i + 1}/${relaysToTest.length}] Testing relay: $relayUrl');
    
    try {
      // 1. Get current user's follow list (for report)
      final initialFollowList = await ref.read(currentUserFollowListProvider.future);

      // 2. Use current follow list as-is (or create empty if none exists)
      final followListData = initialFollowList?.data ?? const FollowListData(list: []);

      // 3. Sign the event
      final signedEvent = await ionNotifier.sign(followListData, useSecp256k1Schnorr: true);
      Logger.log('$_logTag Created signed event: ${signedEvent.id} for $relayUrl');

      // 4. Send to relay
      final actionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
      await ionNotifier.sendEvent(
        signedEvent,
        actionSource: actionSource,
        cache: false,
      );
      Logger.log('$_logTag Sent follow list event ${signedEvent.id} to $relayUrl');

      // 5. Wait for relay to process
      await Future<void>.delayed(const Duration(seconds: 2));

      // 6. Fetch it back
      final requestMessage = RequestMessage();
      requestMessage.addFilter(
        RequestFilter(
          kinds: const [FollowListEntity.kind],
          authors: [signedEvent.pubkey],
          limit: 1,
        ),
      );

      final fetchActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
      final events = await ionNotifier
          .requestEvents(requestMessage, actionSource: fetchActionSource)
          .take(1)
          .toList();

      EventMessage? fetchedEvent;
      bool matched = false;
      String? error;

      if (events.isEmpty) {
        error = 'Event not found on relay';
        Logger.warning('$_logTag Could not fetch back the event from $relayUrl');
      } else {
        fetchedEvent = events.first;
        matched = fetchedEvent.id == signedEvent.id;
        Logger.log(
          '$_logTag Fetched event ${fetchedEvent.id} from $relayUrl. Match: $matched',
        );
      }

      reports.add(
        FollowListTestReport(
          relayUrl: relayUrl,
          initialFollowList: initialFollowList,
          sentEvent: signedEvent,
          fetchedEvent: fetchedEvent,
          error: error,
          success: fetchedEvent != null,
          matched: matched,
        ),
      );
    } catch (e) {
      Logger.error('$_logTag Error testing relay $relayUrl: $e');
      // Create a dummy event for error case
      final dummyEvent = EventMessage(
        id: '',
        pubkey: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: FollowListEntity.kind,
        tags: [],
        content: '',
        sig: null,
      );
      
      reports.add(
        FollowListTestReport(
          relayUrl: relayUrl,
          initialFollowList: currentFollowList,
          sentEvent: dummyEvent,
          error: e.toString(),
          success: false,
          matched: false,
        ),
      );
    }
  }

  // Print comprehensive report
  Logger.log('\n${"=" * 80}');
  Logger.log('FOLLOW LIST TEST REPORT');
  Logger.log('${"=" * 80}\n');
  
  for (final report in reports) {
    Logger.log(report.summary);
  }
  
  // Summary statistics
  final successful = reports.where((r) => r.success).length;
  final matched = reports.where((r) => r.matched).length;
  final failed = reports.where((r) => !r.success).length;
  
  Logger.log('${"=" * 80}');
  Logger.log('SUMMARY');
  Logger.log('${"=" * 80}');
  Logger.log('Total Relays Tested: ${reports.length}');
  Logger.log('Successful: $successful');
  Logger.log('Matched: $matched');
  Logger.log('Failed: $failed');
  Logger.log('${"=" * 80}\n');

  return reports;
}

