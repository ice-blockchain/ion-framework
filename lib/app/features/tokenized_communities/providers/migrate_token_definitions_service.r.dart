// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event_marker.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/event_backfill_service.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/token_definition_migration_state.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/migrate_token_definitions_context.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_operation_protected_accounts_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/update_user_metadata_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/file_cache/ion_file_cache_manager.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'migrate_token_definitions_service.r.g.dart';

@riverpod
Future<void>? migrateTokenDefinitionsService(Ref ref) async {
  var stop = false;

  ///
  /// If app is backgrounded, stop the migration.
  /// If app is resumed, invalidate the provider and restart the migration.
  ///
  ref.listen(appLifecycleProvider, (previous, next) {
    if (next == AppLifecycleState.resumed) {
      ref.invalidateSelf();
      stop = false;
    } else {
      stop = true;
    }
  });

  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentUserMasterPubkey == null) return;

  final userMetadata =
      await ref.read(userMetadataProvider(currentUserMasterPubkey, cache: false).future);
  if (userMetadata == null) return;

  final isProtectedAccount = ref
      .watch(tokenOperationProtectedAccountsServiceProvider)
      .isProtectedAccount(currentUserMasterPubkey);
  if (isProtectedAccount) return;

  try {
    if (await _shouldSkipMigration(ref, userMetadata)) return;

    unawaited(_migrateUserMetadata(ref, userMetadata, () => stop));

    final migrationCtx = MigrationContext();
    final filter = _buildRequestFilter(currentUserMasterPubkey);

    final (_, isDone) = await ref.watch(eventBackfillServiceProvider).startBackfill(
          latestEventTimestamp: userMetadata.createdAt,
          limit: 20,
          filter: filter,
          onEvent: migrationCtx.processEvent,
        );

    if (!isDone) return;

    final definitions = migrationCtx.collectTokenDefinitions(currentUserMasterPubkey);
    await _syncTokenDefinitions(ref, definitions);

    if (!stop) {
      await _finalizeMigration(ref, userMetadata, isDone: isDone);
    }
  } catch (e, stackTrace) {
    Logger.error(
      e,
      stackTrace: stackTrace,
      message: '[MIGRATE TOKEN DEFINITIONS SERVICE] migration is failed',
    );
    await SentryService.logException(e, stackTrace: stackTrace);
  }
}

Future<bool> _shouldSkipMigration(Ref ref, UserMetadataEntity userMetadata) async {
  final jsonFileRemoteUrl = userMetadata.data.tokenDefinitionMigrationStatusJson?.url;
  if (jsonFileRemoteUrl != null) {
    final file = await ref.watch(ionConnectFileCacheServiceProvider).getFile(jsonFileRemoteUrl);
    final contents = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final isMigrated =
        TokenDefinitionMigrationState.fromJson(contents).tokenizedCommunitiesLegacyContentMigrated;

    if (isMigrated) {
      final bytes = await file.readAsBytes();
      final cachedFile =
          await ref.watch(ionConnectFileCacheServiceProvider).getFileFromCache(jsonFileRemoteUrl);
      if (cachedFile != null) {
        return true;
      }
      unawaited(
        ref
            .watch(ionConnectFileCacheServiceProvider)
            .putFile(url: jsonFileRemoteUrl, bytes: bytes, fileExtension: 'json'),
      );
      return true;
    }
  }
  return false;
}

Future<void> _migrateUserMetadata(
  Ref ref,
  UserMetadataEntity userMetadata,
  bool Function() shouldStop,
) async {
  final hasProfileTokenDefinition = ref
      .read(
        ionConnectEntityHasTokenDefinitionProvider(
          eventReference: userMetadata.toEventReference(),
        ),
      )
      .valueOrNull
      .falseOrValue;

  if (!hasProfileTokenDefinition) {
    if (shouldStop()) return;

    final tokenDefinition = CommunityTokenDefinitionIon.fromEventReference(
      eventReference: ReplaceableEventReference(
        masterPubkey: userMetadata.masterPubkey,
        kind: UserMetadataEntity.kind,
      ),
      kind: UserMetadataEntity.kind,
      type: CommunityTokenDefinitionIonType.original,
    );

    await _syncTokenDefinitions(ref, [tokenDefinition]);
  }
}

RequestFilter _buildRequestFilter(String currentUserMasterPubkey) {
  return RequestFilter(
    kinds: const [
      ModifiablePostEntity.kind,
      ArticleEntity.kind,
      PostEntity.kind,
    ],
    authors: [currentUserMasterPubkey],
    search: SearchExtensions([
      TagMarkerSearchExtension(
        tagName: RelatedReplaceableEvent.tagName,
        marker: RelatedEventMarker.reply.toShortString(),
        negative: true,
      ),
      TagMarkerSearchExtension(
        tagName: RelatedImmutableEvent.tagName,
        marker: RelatedEventMarker.reply.toShortString(),
        negative: true,
      ),
      ExpirationSearchExtension(expiration: false),
      ...SearchExtensions.withTokens().extensions,
      ...SearchExtensions.withTokens(forKind: PostEntity.kind).extensions,
      ...SearchExtensions.withTokens(forKind: ArticleEntity.kind).extensions,
    ]).toString(),
  );
}

Future<void> _syncTokenDefinitions(Ref ref, List<CommunityTokenDefinitionIon> definitions) async {
  if (definitions.isEmpty) return;

  final notifier = ref.read(ionConnectNotifierProvider.notifier);

  final tokenDefinitionEvents = await Future.wait(definitions.map(notifier.sign));

  if (tokenDefinitionEvents.isEmpty) return;

  await notifier.sendEvents(tokenDefinitionEvents);
  for (final tokenDefinitionEvent in tokenDefinitionEvents) {
    unawaited(
      (await ref.read(communityTokenDefinitionRepositoryProvider.future))
          .cacheTokenDefinitionReference(tokenDefinitionEvent),
    );
  }
}

Future<void> _finalizeMigration(
  Ref ref,
  UserMetadataEntity userMetadata, {
  required bool isDone,
}) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$migrationStatusJsonFileName.json');
  final jsonString =
      TokenDefinitionMigrationState(tokenizedCommunitiesLegacyContentMigrated: isDone).toJson();
  await file.writeAsString(json.encode(jsonString));

  final mediaFile = MediaFile(
    path: file.path,
    mimeType: MimeType.json.value,
  );

  final media = await ref.read(ionConnectUploadNotifierProvider.notifier).upload(
        mediaFile,
        skipDimCheck: true,
        alt: migrationStatusJsonFileName,
      );

  await ref.read(updateUserMetadataNotifierProvider.notifier).publish(
        userMetadata.data,
        tokenDefinitionMigrationStatusJson: media.mediaAttachment,
      );
}
