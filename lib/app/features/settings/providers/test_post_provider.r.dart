// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/settings/model/available_relays.dart';
import 'package:ion/app/features/settings/providers/selected_relay_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'test_post_provider.r.g.dart';

const _logTag = '[TEST_POST]';

/// Report class for post test results
class PostTestReport {
  const PostTestReport({
    required this.relayUrl,
    required this.sentPost,
    this.fetchedPost,
    this.error,
    required this.success,
    required this.matched,
  });

  final String relayUrl;
  final EventMessage sentPost;
  final EventMessage? fetchedPost;
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
    
    buffer.writeln('\nFetched Post:');
    if (fetchedPost != null) {
      buffer.writeln('  ID: ${fetchedPost!.id}');
      buffer.writeln('  Pubkey: ${fetchedPost!.pubkey}');
      buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(fetchedPost!.createdAt * 1000)}');
      final fetchedContentPreview = fetchedPost!.content.length > 50 
          ? '${fetchedPost!.content.substring(0, 50)}...' 
          : fetchedPost!.content;
      buffer.writeln('  Content: $fetchedContentPreview');
      buffer.writeln('  Match: ${fetchedPost!.id == sentPost.id ? "✓ IDs match" : "✗ IDs differ"}');
    } else {
      buffer.writeln('  None (not fetched)');
    }
    
    buffer.writeln('\n');
    return buffer.toString();
  }
}

/// Tests NIP-01 (kind 1 posts) compatibility by:
/// 1. Creating a post event
/// 2. Sending it to the selected relay
/// 3. Fetching it back to verify it was stored correctly
@riverpod
Future<EventMessage?> testPostOnSelectedRelay(
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
    content: 'Test post for verification - ${DateTime.now().toIso8601String()}',
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

  // 4. Fetch post back
  final requestMessage = RequestMessage();
  requestMessage.addFilter(
    RequestFilter(
      kinds: const [PostEntity.kind],
      authors: [postEvent.pubkey],
      limit: 1,
    ),
  );

  final fetchActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  final events = await ionNotifier
      .requestEvents(requestMessage, actionSource: fetchActionSource)
      .take(1)
      .toList();

  if (events.isEmpty) {
    Logger.warning('$_logTag Could not fetch back the post from $selectedRelay');
    return null;
  }

  final fetchedEvent = events.first;
  Logger.log(
    '$_logTag Successfully fetched post ${fetchedEvent.id} from $selectedRelay. '
    'Content: ${fetchedEvent.content.substring(0, fetchedEvent.content.length > 50 ? 50 : fetchedEvent.content.length)}...',
  );

  return fetchedEvent;
}

/// Tests posts on all popular relays one by one and returns detailed reports
@riverpod
Future<List<PostTestReport>> testPostOnAllRelays(
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

  final reports = <PostTestReport>[];
  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  // Test each relay one by one
  for (var i = 0; i < relaysToTest.length; i++) {
    final relayUrl = relaysToTest[i];
    Logger.log('$_logTag [${i + 1}/${relaysToTest.length}] Testing relay: $relayUrl');
    
    try {
      // 1. Create a test post
      final postData = PostData(
        content: 'Test post for verification - ${DateTime.now().toIso8601String()}',
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

      // 4. Fetch post back
      final requestMessage = RequestMessage();
      requestMessage.addFilter(
        RequestFilter(
          kinds: const [PostEntity.kind],
          authors: [postEvent.pubkey],
          limit: 1,
        ),
      );

      final fetchActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
      final events = await ionNotifier
          .requestEvents(requestMessage, actionSource: fetchActionSource)
          .take(1)
          .toList();

      final fetchedEvent = events.isNotEmpty ? events.first : null;
      final matched = fetchedEvent != null && fetchedEvent.id == postEvent.id;

      if (fetchedEvent != null) {
        Logger.log('$_logTag Successfully fetched post ${fetchedEvent.id} from $relayUrl');
      } else {
        Logger.warning('$_logTag Could not fetch back the post from $relayUrl');
      }

      reports.add(
        PostTestReport(
          relayUrl: relayUrl,
          sentPost: postEvent,
          fetchedPost: fetchedEvent,
          success: fetchedEvent != null,
          matched: matched,
        ),
      );

      Logger.log('$_logTag ${reports.last.summary}');
    } catch (e, stackTrace) {
      Logger.error('$_logTag Error testing relay $relayUrl: $e\n$stackTrace');
      reports.add(
        PostTestReport(
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


