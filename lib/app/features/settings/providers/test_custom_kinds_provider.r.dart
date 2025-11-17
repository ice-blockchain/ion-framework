// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_published_at.f.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/settings/model/available_relays.dart';
import 'package:ion/app/features/settings/providers/selected_relay_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'test_custom_kinds_provider.r.g.dart';

const _logTag = '[TEST_CUSTOM_KINDS]';

/// Report class for custom kind test results
class CustomKindTestReport {
  const CustomKindTestReport({
    required this.relayUrl,
    required this.kind,
    required this.sentEvent,
    this.fetchedEvent,
    this.error,
    required this.success,
    required this.matched,
  });

  final String relayUrl;
  final int kind;
  final EventMessage sentEvent;
  final EventMessage? fetchedEvent;
  final String? error;
  final bool success;
  final bool matched;

  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('=== Relay: $relayUrl ===');
    buffer.writeln('Kind: $kind');
    buffer.writeln('Success: $success');
    buffer.writeln('Matched: $matched');
    
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    
    buffer.writeln('\nSent Event:');
    buffer.writeln('  ID: ${sentEvent.id}');
    buffer.writeln('  Pubkey: ${sentEvent.pubkey}');
    buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(sentEvent.createdAt * 1000)}');
    final contentPreview = sentEvent.content.length > 50 
        ? '${sentEvent.content.substring(0, 50)}...' 
        : sentEvent.content;
    buffer.writeln('  Content: $contentPreview');
    buffer.writeln('  Tags: ${sentEvent.tags.length} tags');
    
    buffer.writeln('\nFetched Event:');
    if (fetchedEvent != null) {
      buffer.writeln('  ID: ${fetchedEvent!.id}');
      buffer.writeln('  Pubkey: ${fetchedEvent!.pubkey}');
      buffer.writeln('  Created At: ${DateTime.fromMillisecondsSinceEpoch(fetchedEvent!.createdAt * 1000)}');
      final fetchedContentPreview = fetchedEvent!.content.length > 50 
          ? '${fetchedEvent!.content.substring(0, 50)}...' 
          : fetchedEvent!.content;
      buffer.writeln('  Content: $fetchedContentPreview');
      buffer.writeln('  Match: ${fetchedEvent!.id == sentEvent.id ? "✓ IDs match" : "✗ IDs differ"}');
    } else {
      buffer.writeln('  None (not fetched)');
    }
    
    buffer.writeln('\n');
    return buffer.toString();
  }
}

/// Tests kind 30175 (ModifiablePostEntity) compatibility by:
/// 1. Creating a modifiable post event
/// 2. Sending it to the selected relay
/// 3. Fetching it back to verify it was stored correctly
@riverpod
Future<EventMessage?> testModifiablePostOnSelectedRelay(
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

  Logger.log('$_logTag Starting modifiable post test on selected relay: $selectedRelay');

  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  // 1. Create a test modifiable post
  final postData = ModifiablePostData(
    textContent: 'Test modifiable post for verification - ${DateTime.now().toIso8601String()}',
    media: const {},
    replaceableEventId: ReplaceableEventIdentifier.generate(),
    publishedAt: EntityPublishedAt(value: DateTime.now().microsecondsSinceEpoch),
  );

  final postEvent = await ionNotifier.sign(postData, useSecp256k1Schnorr: true);
  Logger.log('$_logTag Created modifiable post event: ${postEvent.id}');

  // 2. Send post to selected relay
  final postActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  await ionNotifier.sendEvent(
    postEvent,
    actionSource: postActionSource,
    cache: false,
  );
  Logger.log('$_logTag Sent modifiable post event ${postEvent.id} to $selectedRelay');

  // 3. Wait a bit for relay to process
  await Future<void>.delayed(const Duration(seconds: 2));

  // 4. Fetch post back using replaceable event reference
  final requestMessage = RequestMessage();
  requestMessage.addFilter(
    RequestFilter(
      kinds: const [ModifiablePostEntity.kind],
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
    Logger.warning('$_logTag Could not fetch back the modifiable post from $selectedRelay');
    return null;
  }

  final fetchedEvent = events.first;
  Logger.log(
    '$_logTag Successfully fetched modifiable post ${fetchedEvent.id} from $selectedRelay',
  );

  return fetchedEvent;
}

/// Tests kind 30023 (ArticleEntity) compatibility by:
/// 1. Creating an article event
/// 2. Sending it to the selected relay
/// 3. Fetching it back to verify it was stored correctly
@riverpod
Future<EventMessage?> testArticleOnSelectedRelay(
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

  Logger.log('$_logTag Starting article test on selected relay: $selectedRelay');

  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  // 1. Create a test article
  final articleData = ArticleData(
    textContent: 'Test article content for verification - ${DateTime.now().toIso8601String()}',
    media: const {},
    replaceableEventId: ReplaceableEventIdentifier.generate(),
    publishedAt: EntityPublishedAt(value: DateTime.now().microsecondsSinceEpoch),
    title: 'Test Article',
    summary: 'This is a test article for NIP compatibility testing',
  );

  final articleEvent = await ionNotifier.sign(articleData, useSecp256k1Schnorr: true);
  Logger.log('$_logTag Created article event: ${articleEvent.id}');

  // 2. Send article to selected relay
  final articleActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  await ionNotifier.sendEvent(
    articleEvent,
    actionSource: articleActionSource,
    cache: false,
  );
  Logger.log('$_logTag Sent article event ${articleEvent.id} to $selectedRelay');

  // 3. Wait a bit for relay to process
  await Future<void>.delayed(const Duration(seconds: 2));

  // 4. Fetch article back
  final requestMessage = RequestMessage();
  requestMessage.addFilter(
    RequestFilter(
      kinds: const [ArticleEntity.kind],
      authors: [articleEvent.pubkey],
      limit: 1,
    ),
  );

  final fetchActionSource = ActionSource.relayUrl(selectedRelay, anonymous: true);
  final events = await ionNotifier
      .requestEvents(requestMessage, actionSource: fetchActionSource)
      .take(1)
      .toList();

  if (events.isEmpty) {
    Logger.warning('$_logTag Could not fetch back the article from $selectedRelay');
    return null;
  }

  final fetchedEvent = events.first;
  Logger.log(
    '$_logTag Successfully fetched article ${fetchedEvent.id} from $selectedRelay',
  );

  return fetchedEvent;
}

/// Tests modifiable posts (kind 30175) on all popular relays one by one
@riverpod
Future<List<CustomKindTestReport>> testModifiablePostOnAllRelays(
  Ref ref,
) async {
  final currentUserPubkey = ref.read(currentPubkeySelectorProvider);
  if (currentUserPubkey == null) {
    Logger.warning('$_logTag User not authenticated');
    throw Exception('User not authenticated');
  }

  Logger.log('$_logTag Starting modifiable post test on popular relays');

  final relaysToTest = AvailableRelays.popularRelays;
  Logger.log('$_logTag Found ${relaysToTest.length} relays to test');

  final reports = <CustomKindTestReport>[];
  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  for (var i = 0; i < relaysToTest.length; i++) {
    final relayUrl = relaysToTest[i];
    Logger.log('$_logTag [${i + 1}/${relaysToTest.length}] Testing relay: $relayUrl');
    
    try {
      // 1. Create a test modifiable post
      final postData = ModifiablePostData(
        textContent: 'Test modifiable post for verification - ${DateTime.now().toIso8601String()}',
        media: const {},
        replaceableEventId: ReplaceableEventIdentifier.generate(),
        publishedAt: EntityPublishedAt(value: DateTime.now().microsecondsSinceEpoch),
      );

      final postEvent = await ionNotifier.sign(postData, useSecp256k1Schnorr: true);
      Logger.log('$_logTag Created modifiable post event: ${postEvent.id} for $relayUrl');

      // 2. Send post to relay
      final postActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
      await ionNotifier.sendEvent(
        postEvent,
        actionSource: postActionSource,
        cache: false,
      );
      Logger.log('$_logTag Sent modifiable post event ${postEvent.id} to $relayUrl');

      // 3. Wait for relay to process
      await Future<void>.delayed(const Duration(seconds: 2));

      // 4. Fetch post back
      final requestMessage = RequestMessage();
      requestMessage.addFilter(
        RequestFilter(
          kinds: const [ModifiablePostEntity.kind],
          authors: [postEvent.pubkey],
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
        Logger.warning('$_logTag Could not fetch back the modifiable post from $relayUrl');
      } else {
        fetchedEvent = events.first;
        matched = fetchedEvent.id == postEvent.id;
        Logger.log(
          '$_logTag Fetched modifiable post ${fetchedEvent.id} from $relayUrl. Match: $matched',
        );
      }

      reports.add(
        CustomKindTestReport(
          relayUrl: relayUrl,
          kind: ModifiablePostEntity.kind,
          sentEvent: postEvent,
          fetchedEvent: fetchedEvent,
          error: error,
          success: fetchedEvent != null,
          matched: matched,
        ),
      );
    } catch (e, stackTrace) {
      Logger.error('$_logTag Error testing relay $relayUrl: $e\n$stackTrace');
      final dummyEvent = EventMessage(
        id: '',
        pubkey: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: ModifiablePostEntity.kind,
        tags: [],
        content: '',
        sig: null,
      );
      
      reports.add(
        CustomKindTestReport(
          relayUrl: relayUrl,
          kind: ModifiablePostEntity.kind,
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
  Logger.log('MODIFIABLE POST (30175) TEST REPORT');
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

/// Tests articles (kind 30023) on all popular relays one by one
@riverpod
Future<List<CustomKindTestReport>> testArticleOnAllRelays(
  Ref ref,
) async {
  final currentUserPubkey = ref.read(currentPubkeySelectorProvider);
  if (currentUserPubkey == null) {
    Logger.warning('$_logTag User not authenticated');
    throw Exception('User not authenticated');
  }

  Logger.log('$_logTag Starting article test on popular relays');

  final relaysToTest = AvailableRelays.popularRelays;
  Logger.log('$_logTag Found ${relaysToTest.length} relays to test');

  final reports = <CustomKindTestReport>[];
  final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

  for (var i = 0; i < relaysToTest.length; i++) {
    final relayUrl = relaysToTest[i];
    Logger.log('$_logTag [${i + 1}/${relaysToTest.length}] Testing relay: $relayUrl');
    
    try {
      // 1. Create a test article
      final articleData = ArticleData(
        textContent: 'Test article content for verification - ${DateTime.now().toIso8601String()}',
        media: const {},
        replaceableEventId: ReplaceableEventIdentifier.generate(),
        publishedAt: EntityPublishedAt(value: DateTime.now().microsecondsSinceEpoch),
        title: 'Test Article',
        summary: 'This is a test article for NIP compatibility testing',
      );

      final articleEvent = await ionNotifier.sign(articleData, useSecp256k1Schnorr: true);
      Logger.log('$_logTag Created article event: ${articleEvent.id} for $relayUrl');

      // 2. Send article to relay
      final articleActionSource = ActionSource.relayUrl(relayUrl, anonymous: true);
      await ionNotifier.sendEvent(
        articleEvent,
        actionSource: articleActionSource,
        cache: false,
      );
      Logger.log('$_logTag Sent article event ${articleEvent.id} to $relayUrl');

      // 3. Wait for relay to process
      await Future<void>.delayed(const Duration(seconds: 2));

      // 4. Fetch article back
      final requestMessage = RequestMessage();
      requestMessage.addFilter(
        RequestFilter(
          kinds: const [ArticleEntity.kind],
          authors: [articleEvent.pubkey],
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
        Logger.warning('$_logTag Could not fetch back the article from $relayUrl');
      } else {
        fetchedEvent = events.first;
        matched = fetchedEvent.id == articleEvent.id;
        Logger.log(
          '$_logTag Fetched article ${fetchedEvent.id} from $relayUrl. Match: $matched',
        );
      }

      reports.add(
        CustomKindTestReport(
          relayUrl: relayUrl,
          kind: ArticleEntity.kind,
          sentEvent: articleEvent,
          fetchedEvent: fetchedEvent,
          error: error,
          success: fetchedEvent != null,
          matched: matched,
        ),
      );
    } catch (e, stackTrace) {
      Logger.error('$_logTag Error testing relay $relayUrl: $e\n$stackTrace');
      final dummyEvent = EventMessage(
        id: '',
        pubkey: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: ArticleEntity.kind,
        tags: [],
        content: '',
        sig: null,
      );
      
      reports.add(
        CustomKindTestReport(
          relayUrl: relayUrl,
          kind: ArticleEntity.kind,
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
  Logger.log('ARTICLE (30023) TEST REPORT');
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

