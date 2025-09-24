// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/compressors/video_compressor.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/filesize.dart';
import 'package:video_player/video_player.dart';

part 'compress_test_page.f.freezed.dart';

Timer? debounce;

// Entry point widget with TabBar and TabBarView
class CompressTestPage extends StatelessWidget {
  const CompressTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Media Compression & Video Player'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Video Compression'),
              Tab(text: 'Image Compression'),
              Tab(text: 'Video Player'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            VideoCompressTab(),
            ImageCompressTab(),
            VideoPlayerTab(),
          ],
        ),
      ),
    );
  }
}

// First Tab: Video Compression
class VideoCompressTab extends HookConsumerWidget {
  const VideoCompressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompressing = useState<bool>(false);
    Future<void> pickAndCompressVideo() async {
      final pickedFiles = await FilePicker.platform.pickFiles(
        allowCompression: false,
        allowMultiple: true,
        type: FileType.video,
      );

      if (pickedFiles == null) {
        return;
      }

      isCompressing.value = true;

      final compressedVideos = <VideoInfoModel>[];

      late String compressDirectory;

      final files = pickedFiles.files.sortedBy<num>((e) => e.size);

      for (final file in files) {
        final index = files.indexOf(file);
        final videoCompressor = ref.read(videoCompressorProvider);
        final compressedFile = await videoCompressor.compress(
          MediaFile(path: file.path!),
        );
        final newPath = '${File(compressedFile.path).parent.path}/${index + 1}.mp4';
        File(compressedFile.path).renameSync(newPath);
        Logger.info('Compressed video saved to: $newPath');

        final videoPlayer = CachedVideoPlayerPlus.file(File(newPath)); // or .network() / .asset()
        await videoPlayer.initialize();

        final controller = videoPlayer.controller;
        final duration = controller.value.duration;

        compressedVideos.add(
          VideoInfoModel(
            name: '${index + 1}.mp4',
            originalSize: formattedFileSize(file.path!)!,
            compressedSize: formattedFileSize(newPath)!,
            duration: duration.toString(),
            size: '${compressedFile.width}x${compressedFile.height}',
            fps: '',
            bitRate: '',
          ),
        );
        compressDirectory = File(compressedFile.path).parent.path;
      }

      final file = File(
        '$compressDirectory/compressed_videos_info.txt',
      );
      final buffer = StringBuffer()
        ..writeln('Compressed Videos:')
        ..writeln(
          '| Name           | Original Size  | Compressed Size | Duration       | Size    ',
        )
        ..writeln(
          '|----------------|----------------|-----------------|----------------|----------',
        );
      for (final video in compressedVideos) {
        buffer.writeln(
          '| ${video.name.padRight(14)} | '
          '${video.originalSize.padRight(14)} | '
          '${video.compressedSize.padRight(15)} | '
          '${video.duration.padRight(13)} | '
          '${video.size.padRight(8)}',
        );
      }
      await file.writeAsString(buffer.toString());
      Logger.info('Video compression info saved to: ${file.path}');

      isCompressing.value = false;
    }

    return Column(
      children: [
        ElevatedButton(
          onPressed: pickAndCompressVideo,
          child: const Text('Pick and Compress Video'),
        ),
        const SizedBox(height: 40),
        if (isCompressing.value) const CircularProgressIndicator(),
      ],
    );
  }
}

// Second Tab: Image Compression
class ImageCompressTab extends HookConsumerWidget {
  const ImageCompressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compressedImage = useState<MediaFile?>(null);
    final isCompressing = useState<bool>(false);
    final originalSize = useState<String>('');
    final compressedSize = useState<String>('');

    Future<void> pickAndCompressImage() async {
      final pickedFile = await FilePicker.platform.pickFiles(
        allowCompression: false,
        type: FileType.image,
      );

      if (pickedFile != null) {
        compressedImage.value = null;
        compressedSize.value = '';

        // Display the original image size in MB
        originalSize.value = '${(pickedFile.files.first.size / 1024 / 1024).toStringAsFixed(2)} MB';
        isCompressing.value = true;

        final pickedXFile = XFile(pickedFile.files.first.path!);
        final compressedFile = await ref.read(imageCompressorProvider).compress(
              MediaFile(path: pickedXFile.path),
            );

        // Display the compressed image size in MB
        compressedSize.value =
            '${(await XFile(compressedFile.path).length() / 1024 / 1024).toStringAsFixed(2)} MB';

        compressedImage.value = compressedFile;
        isCompressing.value = false;

        Logger.info('Compressed image saved to: ${compressedFile.path}');
      }
    }

    return Column(
      children: [
        ElevatedButton(
          onPressed: pickAndCompressImage,
          child: const Text('Pick and Compress Image'),
        ),
        if (isCompressing.value) const CircularProgressIndicator(),
        if (originalSize.value.isNotEmpty) Text('Original Size: ${originalSize.value}'),
        if (compressedSize.value.isNotEmpty) Text('Compressed Size: ${compressedSize.value}'),
        if (compressedImage.value != null)
          Image.file(
            File(compressedImage.value!.path),
            height: 200,
            width: 300,
            fit: BoxFit.cover,
          ),
      ],
    );
  }
}

// Third Tab: Video Player with Seek and Scrubbing
class VideoPlayerTab extends HookConsumerWidget {
  const VideoPlayerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteVideoController = ref
        .watch(
          videoControllerProvider(
            const VideoControllerParams(
              sourcePath:
                  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
              looping: true,
            ),
          ),
        )
        .valueOrNull;

    final isPlaying = useState<bool>(false);
    final totalDuration = useState<Duration>(Duration.zero);
    final currentDuration = useState<Duration>(Duration.zero);
    var accumulatedOffset = Duration.zero;

    useOnInit(
      () {
        if (remoteVideoController == null) {
          return;
        }
        totalDuration.value = remoteVideoController.value.duration;
        remoteVideoController.addListener(() {
          isPlaying.value = remoteVideoController.value.isPlaying;
          currentDuration.value = remoteVideoController.value.position;
        });
      },
      [remoteVideoController],
    );

    void handleSeek(Duration seekOffset) {
      if (remoteVideoController == null) {
        return;
      }
      remoteVideoController.pause();
      if (debounce?.isActive ?? false) {
        debounce!.cancel();
      }

      accumulatedOffset += seekOffset;

      debounce = Timer(const Duration(seconds: 1), () async {
        final newPosition = remoteVideoController.value.position + accumulatedOffset;
        final maxDuration = remoteVideoController.value.duration;

        await remoteVideoController
            .seekTo(
          newPosition >= Duration.zero && newPosition <= maxDuration
              ? newPosition
              : (newPosition < Duration.zero ? Duration.zero : maxDuration),
        )
            .then((_) {
          accumulatedOffset = Duration.zero;
          remoteVideoController.play();
        });
      });
    }

    return Center(
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                if (remoteVideoController != null)
                  AspectRatio(
                    aspectRatio: remoteVideoController.value.aspectRatio,
                    child: VideoPlayer(remoteVideoController),
                  ),
                if (remoteVideoController != null)
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: IconButton(
                      icon: Icon(
                        isPlaying.value ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        remoteVideoController.value.isPlaying
                            ? remoteVideoController.pause()
                            : remoteVideoController.play();
                      },
                    ),
                  ),
                if (remoteVideoController != null)
                  PositionedDirectional(
                    bottom: 0,
                    start: 0,
                    end: 0,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        remoteVideoController.setPlaybackSpeed(0.1);
                      },
                      onHorizontalDragEnd: (_) {
                        remoteVideoController.setPlaybackSpeed(1);
                      },
                      child: VideoProgressIndicator(
                        remoteVideoController,
                        colors: VideoProgressColors(
                          playedColor: Colors.red,
                          bufferedColor: Colors.grey.withValues(alpha: 0.5),
                          backgroundColor: Colors.white,
                        ),
                        padding: const EdgeInsets.all(20),
                        allowScrubbing: true,
                      ),
                    ),
                  ),
                PositionedDirectional(
                  bottom: 40,
                  start: 10,
                  child: IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    onPressed: () {
                      handleSeek(const Duration(seconds: -10));
                    },
                  ),
                ),
                PositionedDirectional(
                  bottom: 40,
                  end: 10,
                  child: IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    onPressed: () {
                      handleSeek(const Duration(seconds: 10));
                    },
                  ),
                ),
                PositionedDirectional(
                  bottom: 40,
                  start: 0,
                  end: 0,
                  child: Center(
                    child: Text(
                      '${currentDuration.value.toString().split('.').first} / ${totalDuration.value.toString().split('.').first}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@freezed
class VideoInfoModel with _$VideoInfoModel {
  const factory VideoInfoModel({
    required String name,
    required String originalSize,
    required String compressedSize,
    required String duration,
    required String size,
    required String fps,
    required String bitRate,
  }) = _VideoInfoModel;
}
