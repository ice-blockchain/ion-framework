// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/components/video_preview_duration.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/components/video_preview_edit_cover.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/services/media_service/aspect_ratio.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewCover extends HookConsumerWidget {
  const VideoPreviewCover({
    required this.attachedVideoNotifier,
    super.key,
  });

  final ValueNotifier<MediaFile?> attachedVideoNotifier;

  static const double minAspectRatio = MediaAspectRatio.portrait;
  static const double maxAspectRatio = MediaAspectRatio.landscape;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoPlaying = useState(false);

    final attachedVideo = attachedVideoNotifier.value;

    if (attachedVideo == null) {
      return const SizedBox.shrink();
    }

    final filePath = attachedVideo.path;

    if (filePath.isEmpty) {
      return const _VideoPlaceholder();
    }

    final videoController = ref
        .watch(
          videoControllerProvider(
            // local video - no need to pass authorPubkey for ion connect fallback
            VideoControllerParams(
              sourcePath: filePath,
              looping: true,
              uniqueId: attachedVideo.name ?? '',
            ),
          ),
        )
        .valueOrNull;

    if (videoController == null || !videoController.value.isInitialized) {
      return const _VideoPlaceholder();
    }

    final videoSize = videoController.value.size;
    final videoAspectRatio = videoSize.width / videoSize.height;

    final clampedAspectRatio = videoAspectRatio.clamp(minAspectRatio, maxAspectRatio);

    final thumbFile = useState<File?>(null);
    useOnInit(() {
      final thumbPath = attachedVideoNotifier.value?.thumb;
      File? newThumbFile;
      if (thumbPath != null) {
        final pathFromUri =
            thumbPath.startsWith('file://') ? Uri.parse(thumbPath).toFilePath() : thumbPath;
        newThumbFile = File(pathFromUri);
      } else {
        newThumbFile = null;
      }
      if (newThumbFile != null && newThumbFile.existsSync()) {
        thumbFile.value = newThumbFile;
        //Evict(invalidate) the cached image. Required as thumbnail has always the same file path and name
        FileImage(newThumbFile).evict();
      }
    });

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 16.0.s, start: 12.0.s, end: 12.0.s),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 430.0.s),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0.s),
          child: AspectRatio(
            aspectRatio: clampedAspectRatio,
            child: GestureDetector(
              onTap: () {
                if (videoController.value.isPlaying) {
                  videoController.pause();
                  videoPlaying.value = false;
                } else {
                  videoController.play();
                  videoPlaying.value = true;
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (thumbFile.value != null && !videoPlaying.value)
                    Image.file(
                      thumbFile.value!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  else
                    VideoPlayer(videoController),
                  if (!videoPlaying.value)
                    Container(
                      width: 48.0.s,
                      height: 48.0.s,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.0.s),
                        color: context.theme.appColors.primaryAccent,
                      ),
                      child: IconButton(
                        icon: Assets.svg.iconVideoPlay
                            .icon(color: context.theme.appColors.secondaryBackground),
                        onPressed: () {
                          videoController.play();
                          videoPlaying.value = true;
                        },
                      ),
                    ),
                  PositionedDirectional(
                    end: 12.0.s,
                    bottom: 12.0.s,
                    child: VideoPreviewEditCover(attachedVideoNotifier: attachedVideoNotifier),
                  ),
                  PositionedDirectional(
                    start: 12.0.s,
                    bottom: 12.0.s,
                    child: VideoPreviewDuration(
                      duration: Duration(seconds: videoController.value.duration.inSeconds),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 24.0.s),
      child: Container(
        constraints: BoxConstraints(
          minHeight: 180.0.s,
          maxHeight: 430.0.s,
        ),
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
