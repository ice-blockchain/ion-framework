// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/bool.dart';
import 'package:ion/app/features/core/providers/ion_connect_media_url_fallback_provider.r.dart';
import 'package:ion/app/features/core/providers/mute_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

part 'video_player_provider.r.g.dart';

class NetworkVideosCacheManager {
  static const key = 'networkVideosCacheKey';

  static CacheManager instance = CacheManager(
    Config(
      key,
      maxNrOfCacheObjects: 100,
      stalePeriod: const Duration(days: 1),
    ),
  );
}

@immutable
class VideoControllerParams {
  const VideoControllerParams({
    required this.sourcePath,
    this.authorPubkey,
    this.uniqueId = '',
    this.autoPlay = false,
    this.looping = false,
    this.onlyOneShouldPlay = false,
  });

  final String sourcePath;
  final String? authorPubkey;
  final String
      uniqueId; // an optional uniqueId parameter which should be used when needed independent controllers for the same sourcePath
  final bool autoPlay;
  final bool looping;
  final bool onlyOneShouldPlay;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoControllerParams &&
          other.sourcePath == sourcePath &&
          other.uniqueId == uniqueId;

  @override
  int get hashCode => sourcePath.hashCode ^ uniqueId.hashCode;
}

@riverpod
class VideoController extends _$VideoController {
  /// Tracks the currently playing controller to enforce one-at-a-time playback.
  static VideoPlayerController? _currentlyPlayingController;
  VideoPlayerController? _activeController;

  @override
  Future<Raw<VideoPlayerController>> build(VideoControllerParams params) async {
    final sourcePath = ref.watch(
      iONConnectMediaUrlFallbackProvider
          .select((state) => state[params.sourcePath] ?? params.sourcePath),
    );

    VoidCallback? onlyOneListener;

    try {
      final controller = await ref
          .watch(videoPlayerControllerFactoryProvider(sourcePath))
          .createController(options: VideoPlayerOptions(mixWithOthers: true));

      ref.onCancel(() async {
        if (onlyOneListener != null) {
          controller.removeListener(onlyOneListener);
        }
        await Future.wait([
          () async {
            if (controller.value.isInitialized) {
              await controller.dispose();
            }
          }(),
          () async {
            if (_activeController != null &&
                _activeController != controller &&
                _activeController!.value.isInitialized) {
              await _activeController!.dispose();
              _activeController = null;
            }
          }(),
        ]);
      });

      if (!controller.value.hasError) {
        if (params.looping != controller.value.isLooping) {
          await controller.setLooping(params.looping);
        }

        // Set initial volume based on global mute state
        final isMuted = ref.read(globalMuteNotifierProvider);
        if (isMuted) {
          if (controller.value.volume != 0) {
            await controller.setVolume(0);
          }
        } else if (controller.value.volume != 1) {
          await controller.setVolume(1);
        }

        final prevController = _activeController;
        if (prevController != null) {
          final isPlaying = prevController.value.isBuffering || prevController.value.isPlaying;
          await controller.seekTo(prevController.value.position);
          if (isPlaying) {
            unawaited(controller.play());
          }
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              prevController.dispose();
            },
          );
        } else {
          if (params.autoPlay) {
            unawaited(controller.play());
          }
        }

        _activeController = controller;

        ref.listen(globalMuteNotifierProvider, (_, muted) {
          final prevController = _activeController;
          if (prevController != null) {
            final isPlaying = prevController.value.isPlaying;
            unawaited(
              prevController.setVolume(muted ? 0.0 : 1.0).then((_) {
                if (isPlaying) {
                  prevController.play();
                }
              }),
            );
          }
        });

        if (params.onlyOneShouldPlay) {
          onlyOneListener = () {
            if (controller.value.isPlaying) {
              final prev = VideoController._currentlyPlayingController;
              if (prev != null && prev != controller) {
                prev.pause();
              }
              VideoController._currentlyPlayingController = controller;
            }
          };
          controller.addListener(onlyOneListener);
        }
      }
      return controller;
    } on FailedToInitVideoPlayer catch (error) {
      final authorPubkey = params.authorPubkey;
      if (error.dataSourceType == DataSourceType.network && authorPubkey != null) {
        await ref
            .watch(iONConnectMediaUrlFallbackProvider.notifier)
            .generateFallback(params.sourcePath, authorPubkey: authorPubkey);
      }
      rethrow;
    }
  }
}

class VideoPlayerControllerFactory {
  const VideoPlayerControllerFactory({
    required this.sourcePath,
  });

  final String sourcePath;

  Future<VideoPlayerController> createController({
    VideoPlayerOptions? options,
    bool? forceNetworkDataSource,
  }) async {
    final videoPlayerOptions = options ?? VideoPlayerOptions();

    final player = _getPlayer(videoPlayerOptions, forceNetworkDataSource.falseOrValue);
    try {
      await player.initialize();
      return player.controller;
    } catch (e, stackTrace) {
      Logger.log(
        'Error during video player initialization'
        ' | dataSourceType: ${player.dataSourceType}'
        ' | dataSource: ${player.dataSource}',
        error: e,
        stackTrace: stackTrace,
      );
      if (player.dataSourceType == DataSourceType.file &&
          e.runtimeType == PlatformException &&
          forceNetworkDataSource != true) {
        return createController(
          options: options,
          forceNetworkDataSource: true,
        );
      }
      throw FailedToInitVideoPlayer(
        dataSource: player.dataSource,
        dataSourceType: player.dataSourceType,
      );
    }
  }

  CachedVideoPlayerPlus _getPlayer(
    VideoPlayerOptions videoPlayerOptions,
    bool forceNetworkDataSource,
  ) {
    if (_isNetworkSource(sourcePath) || forceNetworkDataSource) {
      return CachedVideoPlayerPlus.networkUrl(
        _isLocalFile(sourcePath) ? Uri.file(sourcePath) : Uri.parse(sourcePath),
        videoPlayerOptions: videoPlayerOptions,
        cacheManager: NetworkVideosCacheManager.instance,
      );
    } else if (_isLocalFile(sourcePath)) {
      return CachedVideoPlayerPlus.file(
        File(sourcePath),
        videoPlayerOptions: videoPlayerOptions,
      );
    }
    return CachedVideoPlayerPlus.asset(
      sourcePath,
      videoPlayerOptions: videoPlayerOptions,
    );
  }

  bool _isNetworkSource(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  bool _isLocalFile(String path) {
    return !kIsWeb && File(path).existsSync();
  }
}

@riverpod
VideoPlayerControllerFactory videoPlayerControllerFactory(Ref ref, String sourcePath) {
  return VideoPlayerControllerFactory(
    sourcePath: sourcePath,
  );
}
