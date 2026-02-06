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
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event_marker.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/event_backfill_service.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/token_definition_migration_state.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_operation_protected_accounts_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/update_user_metadata_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/file_cache/ion_file_cache_manager.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'migrate_token_definitions_service.r.g.dart';

@riverpod
Future<void>? migrateTokenDefinitionsService(Ref ref) async {
  Logger.log('[MIGRATE SERVICE] START');

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
  if (currentUserMasterPubkey == null) {
    return;
  }

  final userMetadata =
      await ref.read(userMetadataProvider(currentUserMasterPubkey, cache: false).future);
  if (userMetadata == null) {
    return;
  }

  final isProtectedAccount = ref
      .watch(tokenOperationProtectedAccountsServiceProvider)
      .isProtectedAccount(currentUserMasterPubkey);
  if (isProtectedAccount) {
    return;
  }

  final isAlredyMigrated = await _isAlreadyMigrated(ref, userMetadata);
  if (isAlredyMigrated) {
    return;
  }

  unawaited(_migrateUserMetadata(ref, userMetadata, stop: stop));

  final requestFilter = RequestFilter(
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

  Logger.log('[MIGRATE SERVICE] requestFilter: $requestFilter');
  final modifiablePosts = <ModifiablePostEntity>{};
  final modifiablePostEventReferencesHasTokenDefinition = <EventReference>{};

  final posts = <PostEntity>{};
  final postEventReferencesHasTokenDefinition = <EventReference>{};

  final articles = <ArticleEntity>{};
  final articleEventReferencesHasTokenDefinition = <EventReference>{};

  final (lastCreatedAt, isDone) = await ref.watch(eventBackfillServiceProvider).startBackfill(
        latestEventTimestamp: userMetadata.createdAt,
        limit: 2,
        filter: requestFilter,
        onEvent: (event) {
          if (event.kind == ModifiablePostEntity.kind) {
            final modifiablePostEntity = ModifiablePostEntity.fromEventMessage(event);

            if ((modifiablePostEntity.data.relatedEvents?.isEmpty ?? true) &&
                !modifiablePostEntity.isStory) {
              modifiablePosts.add(modifiablePostEntity);
            }
          } else if (event.kind == PostEntity.kind) {
            final postEntity = PostEntity.fromEventMessage(event);
            posts.add(postEntity);
          } else if (event.kind == ArticleEntity.kind) {
            final articleEntity = ArticleEntity.fromEventMessage(event);
            articles.add(articleEntity);
          } else if (event.kind == EventsMetadataEntity.kind) {
            final metadataEntity = EventsMetadataEntity.fromEventMessage(event);

            if (metadataEntity.data.metadata.kind == CommunityTokenDefinitionEntity.kind) {
              final communityTokenDefinitionEntity =
                  CommunityTokenDefinitionEntity.fromEventMessage(
                metadataEntity.data.metadata,
              );
              final communityTokenDefinitionIon =
                  communityTokenDefinitionEntity.data as CommunityTokenDefinitionIon;

              if (communityTokenDefinitionIon.kind == ModifiablePostEntity.kind) {
                modifiablePostEventReferencesHasTokenDefinition
                    .add(communityTokenDefinitionIon.eventReference);
              } else if (communityTokenDefinitionIon.kind == PostEntity.kind) {
                postEventReferencesHasTokenDefinition
                    .add(communityTokenDefinitionIon.eventReference);
              } else if (communityTokenDefinitionIon.kind == ArticleEntity.kind) {
                articleEventReferencesHasTokenDefinition
                    .add(communityTokenDefinitionIon.eventReference);
              }
            }
          }
          // Logger.log('[MIGRATE SERVICE] event.kind: ${event.kind} $event');
        },
      );

  Logger.log('[MIGRATE SERVICE] backfill is done: $isDone');
  if (!isDone) {
    return;
  }

  final allTokenDefinitions = <CommunityTokenDefinitionIon>[];
  for (final post in modifiablePosts) {
    if (modifiablePostEventReferencesHasTokenDefinition.contains(post.toEventReference())) {
      continue;
    }
    final tokenDefinition = CommunityTokenDefinitionIon.fromEventReference(
      eventReference: ReplaceableEventReference(
        masterPubkey: currentUserMasterPubkey,
        kind: ModifiablePostEntity.kind,
        dTag: post.data.replaceableEventId.value,
      ),
      kind: ModifiablePostEntity.kind,
      type: CommunityTokenDefinitionIonType.original,
    );
    allTokenDefinitions.add(tokenDefinition);
  }

  for (final post in posts) {
    if (postEventReferencesHasTokenDefinition.contains(post.toEventReference())) {
      continue;
    }
    final tokenDefinition = CommunityTokenDefinitionIon.fromEventReference(
      eventReference: ImmutableEventReference(
        masterPubkey: currentUserMasterPubkey,
        kind: PostEntity.kind,
        eventId: post.id,
      ),
      kind: PostEntity.kind,
      type: CommunityTokenDefinitionIonType.original,
    );
    allTokenDefinitions.add(tokenDefinition);
  }

  for (final article in articles) {
    if (articleEventReferencesHasTokenDefinition.contains(article.toEventReference())) {
      continue;
    }
    final tokenDefinition = CommunityTokenDefinitionIon.fromEventReference(
      eventReference: ReplaceableEventReference(
        masterPubkey: currentUserMasterPubkey,
        kind: ArticleEntity.kind,
        dTag: article.data.replaceableEventId.value,
      ),
      kind: ArticleEntity.kind,
      type: CommunityTokenDefinitionIonType.original,
    );
    allTokenDefinitions.add(tokenDefinition);
  }

  for (final tokenDefinition in allTokenDefinitions) {
    if (stop) {
      break;
    }
    final tokenDefinitionEvent =
        await ref.watch(ionConnectNotifierProvider.notifier).sign(tokenDefinition);
    unawaited(
      (await ref.read(communityTokenDefinitionRepositoryProvider.future))
          .cacheTokenDefinitionReference(tokenDefinitionEvent),
    );

    await ref.watch(ionConnectNotifierProvider.notifier).sendEvent(tokenDefinitionEvent);
    Logger.log('[MIGRATE SERVICE] synced token definition: ${tokenDefinition.dTag}');
  }

  Logger.log('[MIGRATE SERVICE] ALL DONE');

  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$migrationStatusJsonFileName');
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

    await ref.watch(updateUserMetadataNotifierProvider.notifier).publish(
          userMetadata.data,
          tokenDefinitionMigrationStatusJson: media.mediaAttachment,
        );

    Logger.log('[MIGRATE SERVICE] media: $media');
  } catch (e) {
    Logger.log('[MIGRATE SERVICE] error: $e');
  }

  return;
}

Future<bool> _isAlreadyMigrated(Ref ref, UserMetadataEntity userMetadata) async {
  final jsonFileRemoteUrl = userMetadata.data.tokenDefinitionMigrationStatusJson?.url;
  if (jsonFileRemoteUrl != null) {
    final file = await ref.watch(ionConnectFileCacheServiceProvider).getFile(jsonFileRemoteUrl);
    final contents = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final isMigrated =
        TokenDefinitionMigrationState.fromJson(contents).tokenizedCommunitiesLegacyContentMigrated;
    if (isMigrated) {
      final bytes = await file.readAsBytes();
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
  UserMetadataEntity userMetadata, {
  bool stop = false,
}) async {
  final hasProfileTokenDefinition = ref
      .read(
        ionConnectEntityHasTokenDefinitionProvider(
          eventReference: userMetadata.toEventReference(),
        ),
      )
      .valueOrNull
      .falseOrValue;
  if (!hasProfileTokenDefinition) {
    if (stop) {
      return;
    }
    final tokenDefinition = CommunityTokenDefinitionIon.fromEventReference(
      eventReference: ReplaceableEventReference(
        masterPubkey: userMetadata.masterPubkey,
        kind: UserMetadataEntity.kind,
      ),
      kind: UserMetadataEntity.kind,
      type: CommunityTokenDefinitionIonType.original,
    );
    final tokenDefinitionEvent =
        await ref.watch(ionConnectNotifierProvider.notifier).sign(tokenDefinition);
    unawaited(ref.watch(ionConnectNotifierProvider.notifier).sendEvent(tokenDefinitionEvent));

    unawaited(
      (await ref.read(communityTokenDefinitionRepositoryProvider.future))
          .cacheTokenDefinitionReference(tokenDefinitionEvent),
    );
    Logger.log('[MIGRATE SERVICE] Profile token definition migrated');
  }
}
