// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/suggested_token_details.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/suggested_token_details_state.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/video_frame_extractor.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'suggest_token_creation_details_provider.r.g.dart';

typedef SuggestTokenCreationDetailsFromEventParams = ({
  EventReference eventReference,
  String externalAddress,
  String pubkey,
});

typedef SuggestTokenCreationDetailsParams = ({
  String externalAddress,
  String content,
  CreatorInfo creator,
  List<String> contentVideoFrames,
});

@riverpod
Stream<SuggestedTokenDetailsState?> suggestTokenCreationDetailsFromEvent(
  Ref ref,
  SuggestTokenCreationDetailsFromEventParams params,
) async* {
  var isDisposed = false;
  ref.onDispose(() {
    isDisposed = true;
  });

  try {
    // Check if token already exists, and proceed only if it does not exist
    final isTokenExists = await ref.read(tokenExistsProvider(params.externalAddress).future);
    if (isTokenExists) {
      yield const SuggestedTokenDetailsState.skipped();
      return;
    }
    // Get entity to extract content
    final entity =
        ref.watch(ionConnectEntityProvider(eventReference: params.eventReference)).valueOrNull;
    if (entity == null) return;

    // Extract content text based on entity type
    final contentText = switch (entity) {
      PostEntity() => entity.data.content.trim(),
      ModifiablePostEntity() => entity.data.textContent.trim(),
      ArticleEntity() => () {
          final parts = <String>[];
          final title = entity.data.title;
          if (title != null && title.isNotEmpty) {
            parts.add(title);
          }
          final content = entity.data.content.trim();
          if (content.isNotEmpty) {
            parts.add(content);
          }
          return parts.join('\n').trim();
        }(),
      _ => null,
    };
    if (contentText == null || contentText.isEmpty) return;
    // Get user metadata for creator info
    final userMetadata = await ref.watch(userMetadataProvider(params.pubkey).future);
    if (userMetadata == null) return;
    // Build creator info
    final creatorInfo = CreatorInfo(
      name: userMetadata.data.displayName.isNotEmpty
          ? userMetadata.data.displayName
          : userMetadata.data.name,
      username: userMetadata.data.name,
      bio: userMetadata.data.about,
      website: userMetadata.data.website,
    );
    // Extract video frames and images
    final contentVideoFrames = await ref.read(extractVideoFramesFromEntityProvider(entity).future);
    // Call the suggest provider
    final response = await ref.read(
      suggestTokenCreationDetailsProvider(
        (
          externalAddress: params.externalAddress,
          content: contentText,
          creator: creatorInfo,
          contentVideoFrames: contentVideoFrames,
        ),
      ).future,
    );

    final details = SuggestedTokenDetails(
      ticker: response?.ticker ?? '',
      name: response?.name ?? '',
      picture: response?.picture ?? '',
    );
    final pictureUrl = details.picture.trim();

    if (pictureUrl.isEmpty) {
      yield SuggestedTokenDetailsState.suggested(suggestedDetails: details);
      return;
    }

    final isAvailable = await _isPictureAvailable(pictureUrl);
    if (isAvailable) {
      yield SuggestedTokenDetailsState.suggested(suggestedDetails: details);
      return;
    }

    // Emit empty picture first, then poll until the image becomes available.
    yield SuggestedTokenDetailsState.suggested(
      suggestedDetails: details.copyWith(picture: ''),
    );

    final deadline = DateTime.now().add(const Duration(minutes: 2));
    const delay = Duration(seconds: 1);

    while (!isDisposed && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(delay);
      if (isDisposed) return;
      if (await _isPictureAvailable(pictureUrl)) {
        yield SuggestedTokenDetailsState.suggested(suggestedDetails: details);
        return;
      }
    }
  } catch (e, stackTrace) {
    Logger.log('suggestTokenCreationDetailsFromEvent error: $e', stackTrace: stackTrace);
    yield const SuggestedTokenDetailsState.skipped();
    return;
  }
}

Future<bool> _isPictureAvailable(String url) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse(url);
    final request = await client.headUrl(uri);
    request.headers.set('User-Agent', 'IonApp/1.0');
    final response = await request.close();
    return response.statusCode != HttpStatus.notFound;
  } catch (e) {
    Logger.log('suggestTokenCreationDetailsFromEvent, isPictureAvailable error: $e');
    return false;
  } finally {
    client.close();
  }
}

@riverpod
Future<SuggestCreationDetailsResponse?> suggestTokenCreationDetails(
  Ref ref,
  SuggestTokenCreationDetailsParams params,
) async {
  try {
    final api = await ref.watch(tradeCommunityTokenApiProvider.future);
    final request = SuggestCreationDetailsRequest(
      content: params.content,
      creator: params.creator,
      contentId: params.externalAddress,
      contentVideoFrames: params.contentVideoFrames,
    );

    return await api.suggestCreationDetails(request);
  } catch (e) {
    // Return null on error - this is a best-effort call
    return null;
  }
}
