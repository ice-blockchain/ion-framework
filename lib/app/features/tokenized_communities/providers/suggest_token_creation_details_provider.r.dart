// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/video_frame_extractor.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/file_cache/ion_cache_manager.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:path_provider/path_provider.dart';
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
Future<SuggestCreationDetailsResponse?> suggestTokenCreationDetailsFromEvent(
  Ref ref,
  SuggestTokenCreationDetailsFromEventParams params,
) async {
  try {
    // Get entity to extract content
    final entity =
        ref.watch(ionConnectEntityProvider(eventReference: params.eventReference)).valueOrNull;
    if (entity == null) return null;

    // Extract content text based on entity type
    String? contentText;
    if (entity is ModifiablePostEntity) {
      contentText = entity.data.textContent.trim();
    } else if (entity is ArticleEntity) {
      final parts = <String>[];
      final title = entity.data.title;
      if (title != null && title.isNotEmpty) {
        parts.add(title);
      }
      final content = entity.data.content.trim();
      if (content.isNotEmpty) {
        parts.add(content);
      }
      contentText = parts.join('\n').trim();
    }
    if (contentText == null || contentText.isEmpty) return null;
    // Get user metadata for creator info
    final userMetadata = await ref.watch(userMetadataProvider(params.pubkey).future);
    if (userMetadata == null) return null;
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
    final contentVideoFrames = await _extractMediaFrames(ref, entity);
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

    return response;
  } catch (e, stackTrace) {
    Logger.log('suggestTokenCreationDetailsFromEvent error: $e', stackTrace: stackTrace);
    return null;
  }
}

/// Extracts video frames from entity video
Future<List<String>> _extractMediaFrames(
  Ref ref,
  dynamic entity,
) async {
  final frames = <String>[];
  if (entity is ModifiablePostEntity) {
    // Extract video frames if videos exist
    if (entity.data.hasVideo) {
      final videos = entity.data.videos;
      if (videos.isNotEmpty) {
        final primaryVideo = videos.first;
        final videoUrl = primaryVideo.url;
        String? videoPath;

        // Determine video path - handle local files or check cache/download remote videos
        if (videoUrl.startsWith('file://')) {
          videoPath = videoUrl.replaceFirst('file://', '');
        } else if (!videoUrl.startsWith('http://') && !videoUrl.startsWith('https://')) {
          // Assume it's a local file path without file:// prefix
          videoPath = videoUrl;
        } else {
          // Check if video is already cached (from PostBody video player)
          try {
            final cachedFileInfo = await IONCacheManager.networkVideos.getFileFromCache(videoUrl);
            if (cachedFileInfo != null) {
              videoPath = cachedFileInfo.file.path;
            } else {
              // Video not in cache, download to temporary file
              videoPath = await _downloadVideoToTempFile(videoUrl);
            }
          } catch (e) {
            // Silently fail - video frame extraction is optional
            videoPath = null;
          }
        }

        // If we have a local path, try to extract frames
        if (videoPath != null) {
          var isTempFile = false;
          File? tempFile;

          try {
            final file = File(videoPath);
            if (file.existsSync()) {
              // Check if this is a temporary file we downloaded (not from cache)
              // Temporary files are in temp directory and contain 'video_frame_extract' in name
              isTempFile = videoPath.contains('video_frame_extract');

              final extractedFrames = await ref.read(extractVideoFramesProvider(videoPath).future);

              // Add MIME type prefix to each frame (video frames are JPEG image thumbnails)
              final framesWithMimeType =
                  extractedFrames.map((frame) => 'data:image/webp;base64,$frame').toList();
              frames.addAll(framesWithMimeType);

              // Mark temporary downloaded file for cleanup (not cached files)
              if (isTempFile) {
                tempFile = file;
              }
            }
          } catch (e) {
            // Silently fail - video frame extraction is optional
          } finally {
            // Clean up temporary downloaded file (not cached files)
            if (tempFile != null && tempFile.existsSync()) {
              try {
                await tempFile.delete();
              } catch (e) {
                // Ignore cleanup errors
              }
            }
          }
        }
      }
    }
  }

  return frames;
}

/// Downloads a video from HTTP/HTTPS URL to a temporary file
/// Returns the path to the temporary file, or null if download fails
Future<String?> _downloadVideoToTempFile(String videoUrl) async {
  final client = HttpClient();
  File? tempFile;

  try {
    final uri = Uri.parse(videoUrl);
    final request = await client.getUrl(uri);
    request.headers.set('User-Agent', 'IonApp/1.0');

    final response = await request.close();
    if (response.statusCode == HttpStatus.ok) {
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      // Ensure file extension for video
      final fileExtension = fileName.contains('.') ? fileName.split('.').last : 'mp4';
      tempFile = File(
        '${tempDir.path}/video_frame_extract_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
      );

      // Download video to temporary file
      await response.pipe(tempFile.openWrite());

      return tempFile.path;
    }
  } catch (e) {
    // Clean up temp file if it was created but download failed
    if (tempFile != null && tempFile.existsSync()) {
      try {
        await tempFile.delete();
      } catch (_) {
        // Ignore cleanup errors
      }
    }
    return null;
  } finally {
    client.close();
  }
  return null;
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
