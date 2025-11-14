// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/extensions/event_message.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/settings/model/available_relays.dart';
import 'package:ion/app/features/settings/providers/selected_relay_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'test_post_deletion_provider.r.g.dart';

const _logTag = '[TEST_POST_DELETION]';

/// Report class for post deletion test results
class PostDeletionTestReport {
  const PostDeletionTestReport({
    required this.relayUrl,
    required this.sentPost,
    required this.sentDeletionEvent,
    this.fetchedDeletionEvent,
    this.error,
    required this.success,
    required this.matched,
  });

  final String relayUrl;
  final EventMessage sentPost;
  final EventMessage sentDeletionEvent;
  final EventMessage? fetchedDeletionEvent;
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
    
    buffer.writeln('\nSent Post:');
    buffer.writeln('  ID: ${sentPost.id}');
    buffer.writeln('  Pubkey: ${sentPost.pubkey}');
    buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(sentPost.createdAt * 1000)}');
    final postContentPreview = sentPost.content.length > 50 
        ? '${sentPost.content.substring(0, 50)}...' 
        : sentPost.content;
    buffer.writeln('  Content: $postContentPreview');
    
    buffer.writeln('\nSent Deletion Event:');
    buffer.writeln('  ID: ${sentDeletionEvent.id}');
    buffer.writeln('  Pubkey: ${sentDeletionEvent.pubkey}');
    buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(sentDeletionEvent.createdAt * 1000)}');
    buffer.writeln('  Tags: ${sentDeletionEvent.tags}');
    
    buffer.writeln('\nFetched Deletion Event:');
    if (fetchedDeletionEvent != null) {
      buffer.writeln('  ID: ${fetchedDeletionEvent!.id}');
      buffer.writeln('  Pubkey: ${fetchedDeletionEvent!.pubkey}');
      buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(fetchedDeletionEvent!.createdAt * 1000)}');
      buffer.writeln('  Tags: ${fetchedDeletionEvent!.tags}');
      buffer.writeln('  Match: ${fetchedDeletionEvent!.id == sentDeletionEvent.id ? "✓ IDs match" : "✗ IDs differ"}');
    } else {
      buffer.writeln('  None (not fetched)');
    }
    
    buffer.writeln('\n');
    return buffer.toString();
  }
}

/// Tests NIP-09 (deletion) compatibility by:
/// 1. Creating a post event
/// 2. Sending it to the selected relay
/// 3. Creating a deletion event for that post
/// 4. Sending the deletion event
/// 5. Fetching the deletion event back to verify it was stored correctly
@riverpod
Future<EventMessage?> testPostDeletionOnSelectedRelay(
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

  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  // 1. Create a test post
  final postData = PostData(
    content: 'Test post for deletion verification - ${DateTime.now().toIso8601String()}',
    media: const {},
  );

  final postEvent = await ionNotifier.sign(postData, useSecp256k1Schnorr: true);
  Logger.log('$_logTag Created post event: ${postEvent.id}');

  // 2. Send post to selected relay
  final postActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  await ionNotifier.sendEvent(
    postEvent,
    actionSource: postActionSource,
    cache: false,
  );
  Logger.log('$_logTag Sent post event ${postEvent.id} to $selectedRelay');

  // 3. Wait a bit for relay to process
  await Future<void>.delayed(const Duration(seconds: 2));

  // 4. Create deletion request for the post
  final deletionRequest = DeletionRequest(
    events: [
      EventToDelete(
        eventReference: ImmutableEventReference(
          eventId: postEvent.id,
          masterPubkey: postEvent.masterPubkey,
          kind: PostEntity.kind,
        ),
      ),
    ],
  );

  final deletionEvent = await ionNotifier.sign(deletionRequest, useSecp256k1Schnorr: true);
  Logger.log('$_logTag Created deletion event: ${deletionEvent.id}');

  // 5. Send deletion event to selected relay
  final deletionActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  await ionNotifier.sendEvent(
    deletionEvent,
    actionSource: deletionActionSource,
    cache: false,
  );
  Logger.log('$_logTag Sent deletion event ${deletionEvent.id} to $selectedRelay');

  // 6. Wait a bit for relay to process
  await Future<void>.delayed(const Duration(seconds: 2));

  // 7. Fetch deletion event back
  final requestMessage = RequestMessage();
  requestMessage.addFilter(
    RequestFilter(
      kinds: const [DeletionRequestEntity.kind],
      authors: [deletionEvent.pubkey],
      limit: 1,
    ),
  );

  final fetchActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  final events = await ionNotifier
      .requestEvents(requestMessage, actionSource: fetchActionSource)
      .take(1)
      .toList();

  if (events.isEmpty) {
    Logger.warning('$_logTag Could not fetch back the deletion event from $selectedRelay');
    return null;
  }

  final fetchedEvent = events.first;
  Logger.log(
    '$_logTag Successfully fetched deletion event ${fetchedEvent.id} from $selectedRelay. '
    'Tags: ${fetchedEvent.tags}',
  );

  return fetchedEvent;
}

/// Tests post deletion on all popular relays one by one and returns detailed reports
@riverpod
Future<List<PostDeletionTestReport>> testPostDeletionOnAllRelays(
  Ref ref,
) async {
  final currentUserPubkey = ref.read(currentPubkeySelectorProvider);
  if (currentUserPubkey == null) {
    Logger.warning('$_logTag User not authenticated');
    throw Exception('User not authenticated');
  }

  Logger.log('$_logTag Starting test on popular relays');

  // Get list of popular relays to test
  final relaysToTest = AvailableRelays.popularRelays;
  Logger.log('$_logTag Found ${relaysToTest.length} relays to test: ${relaysToTest.join(", ")}');

  final reports = <PostDeletionTestReport>[];
  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  // Test each relay one by one
  for (var i = 0; i < relaysToTest.length; i++) {
    final relayUrl = relaysToTest[i];
    Logger.log('$_logTag [${i + 1}/${relaysToTest.length}] Testing relay: $relayUrl');
    
    try {
      // 1. Create a test post
      final postData = PostData(
        content: 'Test post for deletion verification - ${DateTime.now().toIso8601String()}',
        media: const {},
      );

      final postEvent = await ionNotifier.sign(postData, useSecp256k1Schnorr: true);
      Logger.log('$_logTag Created post event: ${postEvent.id} for $relayUrl');

      // 2. Send post to relay
      final postActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
      await ionNotifier.sendEvent(
        postEvent,
        actionSource: postActionSource,
        cache: false,
      );
      Logger.log('$_logTag Sent post event ${postEvent.id} to $relayUrl');

      // 3. Wait for relay to process
      await Future<void>.delayed(const Duration(seconds: 2));

      // 4. Create deletion request
      final deletionRequest = DeletionRequest(
        events: [
          EventToDelete(
            eventReference: ImmutableEventReference(
              eventId: postEvent.id,
              masterPubkey: postEvent.masterPubkey,
              kind: PostEntity.kind,
            ),
          ),
        ],
      );

      final deletionEvent = await ionNotifier.sign(deletionRequest, useSecp256k1Schnorr: true);
      Logger.log('$_logTag Created deletion event: ${deletionEvent.id} for $relayUrl');

      // 5. Send deletion event
      final deletionActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
      await ionNotifier.sendEvent(
        deletionEvent,
        actionSource: deletionActionSource,
        cache: false,
      );
      Logger.log('$_logTag Sent deletion event ${deletionEvent.id} to $relayUrl');

      // 6. Wait for relay to process
      await Future<void>.delayed(const Duration(seconds: 2));

      // 7. Fetch deletion event back
      final requestMessage = RequestMessage();
      requestMessage.addFilter(
        RequestFilter(
          kinds: const [DeletionRequestEntity.kind],
          authors: [deletionEvent.pubkey],
          limit: 1,
        ),
      );

      final fetchActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
      final events = await ionNotifier
          .requestEvents(requestMessage, actionSource: fetchActionSource)
          .take(1)
          .toList();

      final fetchedEvent = events.isNotEmpty ? events.first : null;
      final matched = fetchedEvent != null && fetchedEvent.id == deletionEvent.id;

      if (fetchedEvent != null) {
        Logger.log('$_logTag Successfully fetched deletion event ${fetchedEvent.id} from $relayUrl');
      } else {
        Logger.warning('$_logTag Could not fetch back the deletion event from $relayUrl');
      }

      reports.add(
        PostDeletionTestReport(
          relayUrl: relayUrl,
          sentPost: postEvent,
          sentDeletionEvent: deletionEvent,
          fetchedDeletionEvent: fetchedEvent,
          success: fetchedEvent != null,
          matched: matched,
        ),
      );

      Logger.log('$_logTag ${reports.last.summary}');
    } catch (e, stackTrace) {
      Logger.error('$_logTag Error testing relay $relayUrl: $e\n$stackTrace');
      reports.add(
        PostDeletionTestReport(
          relayUrl: relayUrl,
          sentPost: EventMessage(
            id: '',
            pubkey: '',
            createdAt: 0,
            kind: PostEntity.kind,
            tags: [],
            content: '',
            sig: null,
          ),
          sentDeletionEvent: EventMessage(
            id: '',
            pubkey: '',
            createdAt: 0,
            kind: DeletionRequestEntity.kind,
            tags: [],
            content: '',
            sig: null,
          ),
          error: e.toString(),
          success: false,
          matched: false,
        ),
      );
    }
  }

  Logger.log('$_logTag Test completed. Summary:');
  for (final report in reports) {
    Logger.log('$_logTag ${report.summary}');
  }

  return reports;
}

