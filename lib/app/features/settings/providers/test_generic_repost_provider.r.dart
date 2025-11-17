// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_published_at.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/settings/model/available_relays.dart';
import 'package:ion/app/features/settings/providers/selected_relay_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'test_generic_repost_provider.r.g.dart';

const _logTag = '[TEST_GENERIC_REPOST]';

/// Report class for generic repost test results
class GenericRepostTestReport {
  const GenericRepostTestReport({
    required this.relayUrl,
    required this.repostedKind,
    required this.sourceEvent,
    required this.sentRepost,
    this.fetchedRepost,
    this.error,
    required this.success,
    required this.matched,
  });

  final String relayUrl;
  final int repostedKind;
  final EventMessage sourceEvent;
  final EventMessage sentRepost;
  final EventMessage? fetchedRepost;
  final String? error;
  final bool success;
  final bool matched;

  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('=== Relay: $relayUrl ===');
    buffer.writeln('Reposted Kind: $repostedKind');
    buffer.writeln('Success: $success');
    buffer.writeln('Matched: $matched');
    
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    
    buffer.writeln('\nSource Event:');
    buffer.writeln('  ID: ${sourceEvent.id}');
    buffer.writeln('  Kind: ${sourceEvent.kind}');
    buffer.writeln('  Pubkey: ${sourceEvent.pubkey}');
    
    buffer.writeln('\nSent Generic Repost:');
    buffer.writeln('  ID: ${sentRepost.id}');
    buffer.writeln('  Pubkey: ${sentRepost.pubkey}');
    buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(sentRepost.createdAt * 1000)}');
    buffer.writeln('  Tags: ${sentRepost.tags}');
    
    buffer.writeln('\nFetched Generic Repost:');
    if (fetchedRepost != null) {
      buffer.writeln('  ID: ${fetchedRepost!.id}');
      buffer.writeln('  Pubkey: ${fetchedRepost!.pubkey}');
      buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(fetchedRepost!.createdAt * 1000)}');
      buffer.writeln('  Tags: ${fetchedRepost!.tags}');
      buffer.writeln('  Match: ${fetchedRepost!.id == sentRepost.id ? "✓ IDs match" : "✗ IDs differ"}');
    } else {
      buffer.writeln('  None (not fetched)');
    }
    
    buffer.writeln('\n');
    return buffer.toString();
  }
}

/// Tests kind 16 (GenericRepostEntity) compatibility by:
/// 1. Creating a ModifiablePostEntity (kind 30175) to repost
/// 2. Sending it to the selected relay
/// 3. Creating a GenericRepostData (kind 16) reposting that post
/// 4. Sending the repost to the selected relay
/// 5. Fetching it back to verify it was stored correctly
@riverpod
Future<EventMessage?> testGenericRepostOnSelectedRelay(
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

  Logger.log('$_logTag Starting generic repost test on selected relay: $selectedRelay');

  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  // 1. Create a test ModifiablePostEntity to repost
  final postData = ModifiablePostData(
    textContent: 'Test post for generic repost - ${DateTime.now().toIso8601String()}',
    media: const {},
    replaceableEventId: ReplaceableEventIdentifier.generate(),
    publishedAt: EntityPublishedAt(value: DateTime.now().microsecondsSinceEpoch),
  );

  final postEvent = await ionNotifier.sign(postData, useSecp256k1Schnorr: true);
  Logger.log('$_logTag Created source post event: ${postEvent.id}');

  // 2. Send source post to selected relay
  final postActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  await ionNotifier.sendEvent(
    postEvent,
    actionSource: postActionSource,
    cache: false,
  );
  Logger.log('$_logTag Sent source post event ${postEvent.id} to $selectedRelay');

  // 3. Wait a bit for relay to process
  await Future<void>.delayed(const Duration(seconds: 2));

  // 4. Create GenericRepostData reposting the ModifiablePost
  final eventReference = ReplaceableEventReference(
    kind: ModifiablePostEntity.kind,
    masterPubkey: postEvent.pubkey,
    dTag: postData.replaceableEventId.value,
  );

  final repostData = GenericRepostData(
    kind: ModifiablePostEntity.kind,
    eventReference: eventReference,
    repostedEvent: postEvent, // Include full event in content
  );

  // 5. Sign the generic repost event
  final repostEvent = await ionNotifier.sign(repostData, useSecp256k1Schnorr: true);
  Logger.log('$_logTag Created generic repost event: ${repostEvent.id}');

  // 6. Send repost to selected relay
  final repostActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  await ionNotifier.sendEvent(
    repostEvent,
    actionSource: repostActionSource,
    cache: false,
  );
  Logger.log('$_logTag Sent generic repost event ${repostEvent.id} to $selectedRelay');

  // 7. Wait a bit for relay to process
  await Future<void>.delayed(const Duration(seconds: 2));

  // 8. Fetch repost back
  final requestMessage = RequestMessage();
  requestMessage.addFilter(
    RequestFilter(
      kinds: const [GenericRepostEntity.kind],
      authors: [repostEvent.pubkey],
      limit: 1,
    ),
  );

  final fetchActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  final events = await ionNotifier
      .requestEvents(requestMessage, actionSource: fetchActionSource)
      .take(1)
      .toList();

  if (events.isEmpty) {
    Logger.warning('$_logTag Could not fetch back the generic repost from $selectedRelay');
    return null;
  }

  final fetchedEvent = events.first;
  Logger.log(
    '$_logTag Successfully fetched generic repost ${fetchedEvent.id} from $selectedRelay. '
    'Tags: ${fetchedEvent.tags}',
  );

  return fetchedEvent;
}

/// Tests generic reposts (kind 16) on all popular relays one by one
@riverpod
Future<List<GenericRepostTestReport>> testGenericRepostOnAllRelays(
  Ref ref,
) async {
  final currentUserPubkey = ref.read(currentPubkeySelectorProvider);
  if (currentUserPubkey == null) {
    Logger.warning('$_logTag User not authenticated');
    throw Exception('User not authenticated');
  }

  Logger.log('$_logTag Starting generic repost test on popular relays');

  final relaysToTest = AvailableRelays.popularRelays;
  Logger.log('$_logTag Found ${relaysToTest.length} relays to test');

  final reports = <GenericRepostTestReport>[];
  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  for (var i = 0; i < relaysToTest.length; i++) {
    final relayUrl = relaysToTest[i];
    Logger.log('$_logTag [${i + 1}/${relaysToTest.length}] Testing relay: $relayUrl');
    
    try {
      // 1. Create a test ModifiablePostEntity to repost
      final postData = ModifiablePostData(
        textContent: 'Test post for generic repost - ${DateTime.now().toIso8601String()}',
        media: const {},
        replaceableEventId: ReplaceableEventIdentifier.generate(),
        publishedAt: EntityPublishedAt(value: DateTime.now().microsecondsSinceEpoch),
      );

      final postEvent = await ionNotifier.sign(postData, useSecp256k1Schnorr: true);
      Logger.log('$_logTag Created source post event: ${postEvent.id} for $relayUrl');

      // 2. Send source post to relay
      final postActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
      await ionNotifier.sendEvent(
        postEvent,
        actionSource: postActionSource,
        cache: false,
      );
      Logger.log('$_logTag Sent source post event ${postEvent.id} to $relayUrl');

      // 3. Wait for relay to process
      await Future<void>.delayed(const Duration(seconds: 2));

      // 4. Create GenericRepostData reposting the ModifiablePost
      final eventReference = ReplaceableEventReference(
        kind: ModifiablePostEntity.kind,
        masterPubkey: postEvent.pubkey,
        dTag: postData.replaceableEventId.value,
      );

      final repostData = GenericRepostData(
        kind: ModifiablePostEntity.kind,
        eventReference: eventReference,
        repostedEvent: postEvent,
      );

      // 5. Sign the generic repost event
      final repostEvent = await ionNotifier.sign(repostData, useSecp256k1Schnorr: true);
      Logger.log('$_logTag Created generic repost event: ${repostEvent.id} for $relayUrl');

      // 6. Send repost to relay
      final repostActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
      await ionNotifier.sendEvent(
        repostEvent,
        actionSource: repostActionSource,
        cache: false,
      );
      Logger.log('$_logTag Sent generic repost event ${repostEvent.id} to $relayUrl');

      // 7. Wait for relay to process
      await Future<void>.delayed(const Duration(seconds: 2));

      // 8. Fetch repost back
      final requestMessage = RequestMessage();
      requestMessage.addFilter(
        RequestFilter(
          kinds: const [GenericRepostEntity.kind],
          authors: [repostEvent.pubkey],
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
        error = 'Generic repost not found on relay';
        Logger.warning('$_logTag Could not fetch back the generic repost from $relayUrl');
      } else {
        fetchedEvent = events.first;
        matched = fetchedEvent.id == repostEvent.id;
        Logger.log(
          '$_logTag Fetched generic repost ${fetchedEvent.id} from $relayUrl. Match: $matched',
        );
      }

      reports.add(
        GenericRepostTestReport(
          relayUrl: relayUrl,
          repostedKind: ModifiablePostEntity.kind,
          sourceEvent: postEvent,
          sentRepost: repostEvent,
          fetchedRepost: fetchedEvent,
          error: error,
          success: fetchedEvent != null,
          matched: matched,
        ),
      );
    } catch (e, stackTrace) {
      Logger.error('$_logTag Error testing relay $relayUrl: $e\n$stackTrace');
      final dummySource = EventMessage(
        id: '',
        pubkey: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: ModifiablePostEntity.kind,
        tags: [],
        content: '',
        sig: null,
      );
      final dummyRepost = EventMessage(
        id: '',
        pubkey: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: GenericRepostEntity.kind,
        tags: [],
        content: '',
        sig: null,
      );
      
      reports.add(
        GenericRepostTestReport(
          relayUrl: relayUrl,
          repostedKind: ModifiablePostEntity.kind,
          sourceEvent: dummySource,
          sentRepost: dummyRepost,
          error: e.toString(),
          success: false,
          matched: false,
        ),
      );
    }
  }

  // Print comprehensive report
  Logger.log('\n${"=" * 80}');
  Logger.log('GENERIC REPOST (16) TEST REPORT');
  Logger.log('${"=" * 80}\n');
  
  for (final report in reports) {
    Logger.log(report.summary);
  }
  
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

