// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/settings/model/available_relays.dart';
import 'package:ion/app/features/settings/providers/selected_relay_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'test_repost_provider.r.g.dart';

const _logTag = '[TEST_REPOST]';

/// Report class for repost test results
class RepostTestReport {
  const RepostTestReport({
    required this.relayUrl,
    required this.repostedPost,
    required this.sentRepost,
    this.fetchedRepost,
    this.error,
    required this.success,
    required this.matched,
  });

  final String relayUrl;
  final EventMessage repostedPost;
  final EventMessage sentRepost;
  final EventMessage? fetchedRepost;
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
    
    buffer.writeln('\nReposted Post:');
    buffer.writeln('  ID: ${repostedPost.id}');
    buffer.writeln('  Pubkey: ${repostedPost.pubkey}');
    buffer.writeln('  Content: ${repostedPost.content.length > 50 ? "${repostedPost.content.substring(0, 50)}..." : repostedPost.content}');
    
    buffer.writeln('\nSent Repost:');
    buffer.writeln('  ID: ${sentRepost.id}');
    buffer.writeln('  Pubkey: ${sentRepost.pubkey}');
    buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(sentRepost.createdAt * 1000)}');
    buffer.writeln('  Tags: ${sentRepost.tags}');
    
    buffer.writeln('\nFetched Repost:');
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

/// Tests NIP-18 (kind 6 reposts) compatibility by:
/// 1. Fetching or creating a kind 1 post from the selected relay
/// 2. Creating a kind 6 repost event for that post
/// 3. Sending it to the selected relay
/// 4. Fetching it back to verify it was stored correctly
@riverpod
Future<EventMessage?> testRepostOnSelectedRelay(
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

  Logger.log('$_logTag Starting repost test on selected relay: $selectedRelay');

  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  // 1. Try to fetch a kind 1 post from the relay to repost
  EventMessage postToRepost;
  try {
    final requestMessage = RequestMessage();
    requestMessage.addFilter(
      RequestFilter(
        kinds: const [PostEntity.kind],
        limit: 1,
      ),
    );

    final fetchActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
    final posts = await ionNotifier
        .requestEvents(requestMessage, actionSource: fetchActionSource)
        .take(1)
        .toList();

    if (posts.isEmpty) {
      // If no posts found, create one first
      Logger.log('$_logTag No posts found on relay, creating a test post first');
      final postData = PostData(
        content: 'Test post for repost verification - ${DateTime.now().toIso8601String()}',
        media: const {},
      );

      final postEvent = await ionNotifier.sign(postData, useSecp256k1Schnorr: true);
      final postActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
      await ionNotifier.sendEvent(
        postEvent,
        actionSource: postActionSource,
        cache: false,
      );
      Logger.log('$_logTag Created and sent test post: ${postEvent.id}');
      
      // Wait a bit for relay to process
      await Future<void>.delayed(const Duration(seconds: 2));
      postToRepost = postEvent;
    } else {
      postToRepost = posts.first;
      Logger.log('$_logTag Found post to repost: ${postToRepost.id}');
    }
  } catch (e) {
    Logger.error('$_logTag Error fetching post: $e');
    // Fallback: create a test post
    final postData = PostData(
      content: 'Test post for repost verification - ${DateTime.now().toIso8601String()}',
      media: const {},
    );

    final postEvent = await ionNotifier.sign(postData, useSecp256k1Schnorr: true);
    final postActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
    await ionNotifier.sendEvent(
      postEvent,
      actionSource: postActionSource,
      cache: false,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    postToRepost = postEvent;
  }

  // 2. Create repost data
  final eventReference = ImmutableEventReference(
    eventId: postToRepost.id,
    masterPubkey: postToRepost.pubkey,
  );

  final repostData = RepostData(
    eventReference: eventReference,
    repostedEvent: postToRepost, // Include full event in content
  );

  // 3. Sign the repost event
  final repostEvent = await ionNotifier.sign(repostData, useSecp256k1Schnorr: true);
  Logger.log('$_logTag Created repost event: ${repostEvent.id}');

  // 4. Send repost to selected relay
  final repostActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  await ionNotifier.sendEvent(
    repostEvent,
    actionSource: repostActionSource,
    cache: false,
  );
  Logger.log('$_logTag Sent repost event ${repostEvent.id} to $selectedRelay');

  // 5. Wait a bit for relay to process
  await Future<void>.delayed(const Duration(seconds: 2));

  // 6. Fetch repost back
  final requestMessage = RequestMessage();
  requestMessage.addFilter(
    RequestFilter(
      kinds: const [RepostEntity.kind],
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
    Logger.warning('$_logTag Could not fetch back the repost from $selectedRelay');
    return null;
  }

  final fetchedEvent = events.first;
  Logger.log(
    '$_logTag Successfully fetched repost ${fetchedEvent.id} from $selectedRelay. '
    'Tags: ${fetchedEvent.tags}',
  );

  return fetchedEvent;
}

/// Tests reposts on all popular relays one by one and returns detailed reports
@riverpod
Future<List<RepostTestReport>> testRepostOnAllRelays(
  Ref ref,
) async {
  final currentUserPubkey = ref.read(currentPubkeySelectorProvider);
  if (currentUserPubkey == null) {
    Logger.warning('$_logTag User not authenticated');
    throw Exception('User not authenticated');
  }

  Logger.log('$_logTag Starting repost test on popular relays');

  // Get list of popular relays to test
  final relaysToTest = AvailableRelays.popularRelays;
  Logger.log('$_logTag Found ${relaysToTest.length} relays to test: ${relaysToTest.join(", ")}');

  final reports = <RepostTestReport>[];
  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  // Test each relay one by one
  for (var i = 0; i < relaysToTest.length; i++) {
    final relayUrl = relaysToTest[i];
    Logger.log('$_logTag [${i + 1}/${relaysToTest.length}] Testing relay: $relayUrl');
    
    try {
      // 1. Try to fetch a kind 1 post from the relay to repost
      EventMessage postToRepost;
      try {
        final requestMessage = RequestMessage();
        requestMessage.addFilter(
          RequestFilter(
            kinds: const [PostEntity.kind],
            limit: 1,
          ),
        );

        final fetchActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
        final posts = await ionNotifier
            .requestEvents(requestMessage, actionSource: fetchActionSource)
            .take(1)
            .toList();

        if (posts.isEmpty) {
          // If no posts found, create one first
          Logger.log('$_logTag No posts found on $relayUrl, creating a test post first');
          final postData = PostData(
            content: 'Test post for repost verification - ${DateTime.now().toIso8601String()}',
            media: const {},
          );

          final postEvent = await ionNotifier.sign(postData, useSecp256k1Schnorr: true);
          final postActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
          await ionNotifier.sendEvent(
            postEvent,
            actionSource: postActionSource,
            cache: false,
          );
          Logger.log('$_logTag Created and sent test post: ${postEvent.id} to $relayUrl');
          
          // Wait a bit for relay to process
          await Future<void>.delayed(const Duration(seconds: 2));
          postToRepost = postEvent;
        } else {
          postToRepost = posts.first;
          Logger.log('$_logTag Found post to repost: ${postToRepost.id} from $relayUrl');
        }
      } catch (e) {
        Logger.error('$_logTag Error fetching post from $relayUrl: $e');
        // Fallback: create a test post
        final postData = PostData(
          content: 'Test post for repost verification - ${DateTime.now().toIso8601String()}',
          media: const {},
        );

        final postEvent = await ionNotifier.sign(postData, useSecp256k1Schnorr: true);
        final postActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
        await ionNotifier.sendEvent(
          postEvent,
          actionSource: postActionSource,
          cache: false,
        );
        await Future<void>.delayed(const Duration(seconds: 2));
        postToRepost = postEvent;
      }

      // 2. Create repost data
      final eventReference = ImmutableEventReference(
        eventId: postToRepost.id,
        masterPubkey: postToRepost.pubkey,
      );

      final repostData = RepostData(
        eventReference: eventReference,
        repostedEvent: postToRepost,
      );

      // 3. Sign the repost event
      final repostEvent = await ionNotifier.sign(repostData, useSecp256k1Schnorr: true);
      Logger.log('$_logTag Created repost event: ${repostEvent.id} for $relayUrl');

      // 4. Send repost to relay
      final repostActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
      await ionNotifier.sendEvent(
        repostEvent,
        actionSource: repostActionSource,
        cache: false,
      );
      Logger.log('$_logTag Sent repost event ${repostEvent.id} to $relayUrl');

      // 5. Wait for relay to process
      await Future<void>.delayed(const Duration(seconds: 2));

      // 6. Fetch repost back
      final requestMessage = RequestMessage();
      requestMessage.addFilter(
        RequestFilter(
          kinds: const [RepostEntity.kind],
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
        error = 'Repost not found on relay';
        Logger.warning('$_logTag Could not fetch back the repost from $relayUrl');
      } else {
        fetchedEvent = events.first;
        matched = fetchedEvent.id == repostEvent.id;
        Logger.log(
          '$_logTag Fetched repost ${fetchedEvent.id} from $relayUrl. Match: $matched',
        );
      }

      reports.add(
        RepostTestReport(
          relayUrl: relayUrl,
          repostedPost: postToRepost,
          sentRepost: repostEvent,
          fetchedRepost: fetchedEvent,
          error: error,
          success: fetchedEvent != null,
          matched: matched,
        ),
      );
    } catch (e, stackTrace) {
      Logger.error('$_logTag Error testing relay $relayUrl: $e\n$stackTrace');
      // Create a dummy event for error case
      final dummyPost = EventMessage(
        id: '',
        pubkey: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: PostEntity.kind,
        tags: [],
        content: '',
        sig: null,
      );
      final dummyRepost = EventMessage(
        id: '',
        pubkey: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: RepostEntity.kind,
        tags: [],
        content: '',
        sig: null,
      );
      
      reports.add(
        RepostTestReport(
          relayUrl: relayUrl,
          repostedPost: dummyPost,
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
  Logger.log('REPOST TEST REPORT');
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

