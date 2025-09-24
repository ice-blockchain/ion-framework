// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/bool.dart';
import 'package:ion/app/features/core/providers/ion_connect_media_url_fallback_provider.r.dart';
import 'package:ion/app/features/core/providers/mute_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

part 'video_player_provider.m.freezed.dart';
part 'video_player_provider.m.g.dart';

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

/// Limits how many video controllers are initialized concurrently.
class _ConcurrencyGate {
  _ConcurrencyGate(this.max);

  final int max;
  int _inFlight = 0;
  final Queue<Completer<void>> _queue = Queue();

  Future<void> acquire() {
    if (_inFlight < max) {
      _inFlight++;
      return Future.value();
    }
    final c = Completer<void>();
    _queue.add(c);
    return c.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      _queue.removeFirst().complete();
    } else {
      _inFlight = (_inFlight - 1).clamp(0, max);
    }
  }
}

@Freezed(fromJson: false, toJson: false)
class VideoControllerParams with _$VideoControllerParams {
  const factory VideoControllerParams({
    required String sourcePath,
    String? authorPubkey,
    @Default('')
    String?
        uniqueId, // an optional uniqueId parameter which should be used when needed independent controllers for the same sourcePath
    @Default(false) bool looping,
    @Default(false) bool onlyOneShouldPlay,
  }) = _VideoControllerParams;
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

    // Cancellation signal for in-flight initialization (scroll off / dispose / refresh).
    final cancelInit = Completer<void>();
    ref.onCancel(() {
      if (!cancelInit.isCompleted) cancelInit.complete();
    });

    VoidCallback? onlyOneListener;

    try {
      final controller =
          await ref.watch(videoPlayerControllerFactoryProvider(sourcePath)).createController(
                options: VideoPlayerOptions(mixWithOthers: true),
                cancelToken: cancelInit,
              );

      ref.onCancel(() async {
        if (onlyOneListener != null) {
          controller.removeListener(onlyOneListener);
        }
        await Future.wait([
          () async {
            try {
              await controller.dispose();
            } catch (_) {}
          }(),
          () async {
            final prev = _activeController;
            if (prev != null && prev != controller) {
              try {
                if (identical(VideoController._currentlyPlayingController, prev)) {
                  VideoController._currentlyPlayingController = null;
                }
                await prev.dispose();
              } catch (_) {}
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
              if (identical(VideoController._currentlyPlayingController, prevController)) {
                VideoController._currentlyPlayingController = null;
              }
              prevController.dispose();
            },
          );
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
  static final _initGate = _ConcurrencyGate(Platform.isAndroid ? 1 : 2);
  static const _maxRetryAttempts = 5;

  Future<VideoPlayerController> createController({
    required Completer<void> cancelToken,
    VideoPlayerOptions? options,
    bool? forceNetworkDataSource,
  }) async {
    final videoPlayerOptions = options ?? VideoPlayerOptions();

    await _initGate.acquire();

    // Give Android a tiny breather between controller init
    if (Platform.isAndroid) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    try {
      var backoff = const Duration(milliseconds: 300);
      CachedVideoPlayerPlus? player;
      DataSourceType? lastType;
      String? lastSource;

      for (var attempt = 0; attempt < _maxRetryAttempts; attempt++) {
        // Recreate player each attempt to force a fresh decoder allocation.
        player = _getPlayer(videoPlayerOptions, forceNetworkDataSource.falseOrValue);
        lastType = player.dataSourceType;
        lastSource = player.dataSource;

        // Early cancellation before starting the heavy work.
        if (cancelToken.isCompleted) {
          throw StateError('video_init_cancelled');
        }
        try {
          await player.initialize();
          if (cancelToken.isCompleted) {
            try {
              await player.dispose();
            } catch (_) {}
            throw StateError('video_init_cancelled');
          }
          return player.controller;
        } catch (e, stackTrace) {
          Logger.log(
            'Error during video player initialization (attempt=${attempt + 1})'
            ' | dataSourceType: $lastType'
            ' | dataSource: $lastSource',
            error: e,
            stackTrace: stackTrace,
          );
          try {
            await player.dispose();
          } catch (_) {}

          // If local file path fails, try forcing network once.
          if (lastType == DataSourceType.file &&
              e is PlatformException &&
              forceNetworkDataSource != true) {
            return createController(
              cancelToken: cancelToken,
              options: options,
              forceNetworkDataSource: true,
            );
          }

          if (e is PlatformException) {
            await Future<void>.delayed(backoff);
            final nextMs = (backoff.inMilliseconds * 2).clamp(300, 3000);
            backoff = Duration(milliseconds: nextMs);
            continue;
          }
          break;
        }
      }

      throw FailedToInitVideoPlayer(
        dataSource: lastSource ?? 'unknown',
        dataSourceType: lastType ?? DataSourceType.network,
      );
    } finally {
      _initGate.release();
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
        cacheKey: _cacheKeyFor(sourcePath),
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

  String _cacheKeyFor(String input) {
    try {
      final u = Uri.parse(input);
      return u.path;
    } catch (_) {
      // On parse issues, fall back to the original string.
      return input;
    }
  }
}

@riverpod
VideoPlayerControllerFactory videoPlayerControllerFactory(Ref ref, String sourcePath) {
  return VideoPlayerControllerFactory(
    sourcePath: sourcePath,
  );
}
