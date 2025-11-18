// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
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

part 'test_reaction_provider.r.g.dart';

const _logTag = '[TEST_REACTION]';

/// Report class for reaction test results
class ReactionTestReport {
  const ReactionTestReport({
    required this.relayUrl,
    required this.reactedKind,
    required this.sourceEvent,
    required this.sentReaction,
    this.fetchedReaction,
    this.error,
    required this.success,
    required this.matched,
  });

  final String relayUrl;
  final int reactedKind;
  final EventMessage sourceEvent;
  final EventMessage sentReaction;
  final EventMessage? fetchedReaction;
  final String? error;
  final bool success;
  final bool matched;

  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('=== Relay: $relayUrl ===');
    buffer.writeln('Reacted Kind: $reactedKind');
    buffer.writeln('Success: $success');
    buffer.writeln('Matched: $matched');
    
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    
    buffer.writeln('\nSource Event:');
    buffer.writeln('  ID: ${sourceEvent.id}');
    buffer.writeln('  Kind: ${sourceEvent.kind}');
    buffer.writeln('  Pubkey: ${sourceEvent.pubkey}');
    
    buffer.writeln('\nSent Reaction:');
    buffer.writeln('  ID: ${sentReaction.id}');
    buffer.writeln('  Pubkey: ${sentReaction.pubkey}');
    buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(sentReaction.createdAt * 1000)}');
    buffer.writeln('  Content: ${sentReaction.content}');
    buffer.writeln('  Tags: ${sentReaction.tags}');
    
    buffer.writeln('\nFetched Reaction:');
    if (fetchedReaction != null) {
      buffer.writeln('  ID: ${fetchedReaction!.id}');
      buffer.writeln('  Pubkey: ${fetchedReaction!.pubkey}');
      buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(fetchedReaction!.createdAt * 1000)}');
      buffer.writeln('  Content: ${fetchedReaction!.content}');
      buffer.writeln('  Tags: ${fetchedReaction!.tags}');
      buffer.writeln('  Match: ${fetchedReaction!.id == sentReaction.id ? "✓ IDs match" : "✗ IDs differ"}');
    } else {
      buffer.writeln('  None (not fetched)');
    }
    
    buffer.writeln('\n');
    return buffer.toString();
  }
}

/// Tests kind 7 (ReactionEntity) compatibility by:
/// 1. Creating a ModifiablePostEntity (kind 30175) to react to
/// 2. Sending it to the selected relay
/// 3. Creating a ReactionData (kind 7) reacting to that post
/// 4. Sending the reaction to the selected relay
/// 5. Fetching it back to verify it was stored correctly
@riverpod
Future<EventMessage?> testReactionOnSelectedRelay(
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

  Logger.log('$_logTag Starting reaction test on selected relay: $selectedRelay');

  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  // 1. Create a test ModifiablePostEntity to react to
  final postData = ModifiablePostData(
    textContent: 'Test post for reaction - ${DateTime.now().toIso8601String()}',
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

  // 4. Create ReactionData reacting to the ModifiablePost
  final eventReference = ReplaceableEventReference(
    kind: ModifiablePostEntity.kind,
    masterPubkey: postEvent.pubkey,
    dTag: postData.replaceableEventId.value,
  );

  final reactionData = ReactionData(
    kind: ModifiablePostEntity.kind,
    eventReference: eventReference,
    content: ReactionEntity.likeSymbol, // "+" for like
  );

  // 5. Sign the reaction event
  final reactionEvent = await ionNotifier.sign(reactionData, useSecp256k1Schnorr: true);
  Logger.log('$_logTag Created reaction event: ${reactionEvent.id}');

  // 6. Send reaction to selected relay
  final reactionActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  await ionNotifier.sendEvent(
    reactionEvent,
    actionSource: reactionActionSource,
    cache: false,
  );
  Logger.log('$_logTag Sent reaction event ${reactionEvent.id} to $selectedRelay');

  // 7. Wait a bit for relay to process
  await Future<void>.delayed(const Duration(seconds: 2));

  // 8. Fetch reaction back
  final requestMessage = RequestMessage();
  requestMessage.addFilter(
    RequestFilter(
      kinds: const [ReactionEntity.kind],
      authors: [reactionEvent.pubkey],
      limit: 1,
    ),
  );

  final fetchActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  final events = await ionNotifier
      .requestEvents(requestMessage, actionSource: fetchActionSource)
      .take(1)
      .toList();

  if (events.isEmpty) {
    Logger.warning('$_logTag Could not fetch back the reaction from $selectedRelay');
    return null;
  }

  final fetchedEvent = events.first;
  Logger.log(
    '$_logTag Successfully fetched reaction ${fetchedEvent.id} from $selectedRelay. '
    'Content: ${fetchedEvent.content}, Tags: ${fetchedEvent.tags}',
  );

  return fetchedEvent;
}

/// Tests reactions (kind 7) on all popular relays one by one
@riverpod
Future<List<ReactionTestReport>> testReactionOnAllRelays(
  Ref ref,
) async {
  final currentUserPubkey = ref.read(currentPubkeySelectorProvider);
  if (currentUserPubkey == null) {
    Logger.warning('$_logTag User not authenticated');
    throw Exception('User not authenticated');
  }

  Logger.log('$_logTag Starting reaction test on popular relays');

  final relaysToTest = AvailableRelays.popularRelays;
  Logger.log('$_logTag Found ${relaysToTest.length} relays to test');

  final reports = <ReactionTestReport>[];
  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  for (var i = 0; i < relaysToTest.length; i++) {
    final relayUrl = relaysToTest[i];
    Logger.log('$_logTag [${i + 1}/${relaysToTest.length}] Testing relay: $relayUrl');
    
    try {
      // 1. Create a test ModifiablePostEntity to react to
      final postData = ModifiablePostData(
        textContent: 'Test post for reaction - ${DateTime.now().toIso8601String()}',
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

      // 4. Create ReactionData reacting to the ModifiablePost
      final eventReference = ReplaceableEventReference(
        kind: ModifiablePostEntity.kind,
        masterPubkey: postEvent.pubkey,
        dTag: postData.replaceableEventId.value,
      );

      final reactionData = ReactionData(
        kind: ModifiablePostEntity.kind,
        eventReference: eventReference,
        content: ReactionEntity.likeSymbol, // "+" for like
      );

      // 5. Sign the reaction event
      final reactionEvent = await ionNotifier.sign(reactionData, useSecp256k1Schnorr: true);
      Logger.log('$_logTag Created reaction event: ${reactionEvent.id} for $relayUrl');

      // 6. Send reaction to relay
      final reactionActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
      await ionNotifier.sendEvent(
        reactionEvent,
        actionSource: reactionActionSource,
        cache: false,
      );
      Logger.log('$_logTag Sent reaction event ${reactionEvent.id} to $relayUrl');

      // 7. Wait for relay to process
      await Future<void>.delayed(const Duration(seconds: 2));

      // 8. Fetch reaction back
      final requestMessage = RequestMessage();
      requestMessage.addFilter(
        RequestFilter(
          kinds: const [ReactionEntity.kind],
          authors: [reactionEvent.pubkey],
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
        error = 'Reaction not found on relay';
        Logger.warning('$_logTag Could not fetch back the reaction from $relayUrl');
      } else {
        fetchedEvent = events.first;
        matched = fetchedEvent.id == reactionEvent.id;
        Logger.log(
          '$_logTag Fetched reaction ${fetchedEvent.id} from $relayUrl. Match: $matched',
        );
      }

      reports.add(
        ReactionTestReport(
          relayUrl: relayUrl,
          reactedKind: ModifiablePostEntity.kind,
          sourceEvent: postEvent,
          sentReaction: reactionEvent,
          fetchedReaction: fetchedEvent,
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
      final dummyReaction = EventMessage(
        id: '',
        pubkey: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: ReactionEntity.kind,
        tags: [],
        content: '',
        sig: null,
      );
      
      reports.add(
        ReactionTestReport(
          relayUrl: relayUrl,
          reactedKind: ModifiablePostEntity.kind,
          sourceEvent: dummySource,
          sentReaction: dummyReaction,
          error: e.toString(),
          success: false,
          matched: false,
        ),
      );
    }
  }

  // Print comprehensive report
  Logger.log('\n${"=" * 80}');
  Logger.log('REACTION (7) TEST REPORT');
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

