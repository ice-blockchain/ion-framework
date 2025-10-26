// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/back_hardware_button_interceptor/back_hardware_button_interceptor.dart';
import 'package:ion/app/components/text_editor/text_editor.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/components/create_post_app_bar.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/components/create_post_bottom_panel.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/components/create_post_content.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/hooks/use_attached_media_files.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/hooks/use_attached_media_links.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/hooks/use_attached_video.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/hooks/use_post_quill_controller.dart';
import 'package:ion/app/features/feed/hooks/use_detect_language.dart';
import 'package:ion/app/features/feed/hooks/use_preselect_language.dart';
import 'package:ion/app/features/feed/hooks/use_preselect_topics.dart';
import 'package:ion/app/features/feed/views/pages/cancel_creation_modal/cancel_creation_modal.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:ion/app/features/feed/create_post/providers/media_nsfw_parallel_checker.m.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class PostFormModal extends HookConsumerWidget {
  const PostFormModal._({
    required this.createOption,
    super.key,
    this.parentEvent,
    this.quotedEvent,
    this.modifiedEvent,
    this.content,
    this.videoPath,
    this.attachedMedia,
    this.mimeType,
    this.videoThumbPath,
  });

  factory PostFormModal.createPost({
    Key? key,
    String? content,
    String? attachedMedia,
  }) {
    return PostFormModal._(
      key: key,
      createOption: CreatePostOption.plain,
      content: content,
      attachedMedia: attachedMedia,
    );
  }

  factory PostFormModal.editPost({
    required EventReference modifiedEvent,
    Key? key,
    String? content,
    String? attachedMedia,
  }) {
    return PostFormModal._(
      key: key,
      createOption: CreatePostOption.modify,
      modifiedEvent: modifiedEvent,
      content: content,
      attachedMedia: attachedMedia,
    );
  }

  factory PostFormModal.createReply({
    required EventReference parentEvent,
    Key? key,
    String? content,
    String? attachedMedia,
  }) {
    return PostFormModal._(
      key: key,
      createOption: CreatePostOption.reply,
      parentEvent: parentEvent,
      content: content,
      attachedMedia: attachedMedia,
    );
  }

  factory PostFormModal.editReply({
    required EventReference parentEvent,
    required EventReference modifiedEvent,
    Key? key,
    String? content,
    String? attachedMedia,
  }) {
    return PostFormModal._(
      key: key,
      createOption: CreatePostOption.reply,
      parentEvent: parentEvent,
      modifiedEvent: modifiedEvent,
      content: content,
      attachedMedia: attachedMedia,
    );
  }

  factory PostFormModal.createQuote({
    required EventReference quotedEvent,
    Key? key,
    String? content,
    String? attachedMedia,
  }) {
    return PostFormModal._(
      key: key,
      createOption: CreatePostOption.quote,
      quotedEvent: quotedEvent,
      content: content,
      attachedMedia: attachedMedia,
    );
  }

  factory PostFormModal.editQuote({
    required EventReference quotedEvent,
    required EventReference modifiedEvent,
    Key? key,
    String? content,
    String? attachedMedia,
  }) {
    return PostFormModal._(
      key: key,
      createOption: CreatePostOption.quote,
      quotedEvent: quotedEvent,
      modifiedEvent: modifiedEvent,
      content: content,
      attachedMedia: attachedMedia,
    );
  }

  factory PostFormModal.video({
    required String videoPath,
    required String mimeType,
    String? videoThumbPath,
    Key? key,
    String? content,
  }) {
    return PostFormModal._(
      key: key,
      createOption: CreatePostOption.video,
      videoPath: videoPath,
      mimeType: mimeType,
      content: content,
      videoThumbPath: videoThumbPath,
    );
  }

  final CreatePostOption createOption;
  final EventReference? parentEvent;
  final EventReference? quotedEvent;
  final EventReference? modifiedEvent;
  final String? content;
  final String? videoPath;
  final String? videoThumbPath;
  final String? attachedMedia;
  final String? mimeType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textEditorController = usePostQuillController(
      ref,
      content: content,
      modifiedEvent: modifiedEvent,
    );
    final scrollController = useScrollController();
    final textEditorKey = useMemoized(TextEditorKeys.createPost);

    final attachedVideoNotifier =
        useAttachedVideo(videoPath: videoPath, mimeType: mimeType, videoThumbPath: videoThumbPath);
    final attachedMediaFilesNotifier =
        useAttachedMediaFilesNotifier(ref, attachedMedia: attachedMedia);
    final attachedMediaLinksNotifier =
        useAttachedMediaLinksNotifier(ref, eventReference: modifiedEvent);

    usePreselectTopics(ref, eventReference: modifiedEvent);
    usePreselectLanguage(ref, eventReference: modifiedEvent);
    useDetectLanguage(ref, enabled: parentEvent == null, quillController: textEditorController);

    if (textEditorController == null) {
      return const SizedBox.shrink();
    }

    // TODO: Run only if media files are added or changed.
    final mediaFiles = attachedMediaFilesNotifier.value;
    final mediaCount = mediaFiles.length;
    print('🔥DEBUG: Media files count: $mediaCount, files: $mediaFiles');

    // NSFW check for media files (images, etc.)
    useEffect(() {
      print('🔥UseEffect() TRIGGERED! Media files: $mediaFiles (count: $mediaCount)');
      if (mediaFiles.isNotEmpty) {
        print('🔥Calling NSFW check for ${mediaFiles.length} files');

        // Schedule NSFW check to run after the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            // Convert asset IDs to actual file paths before NSFW check
            final convertedMediaFiles = await ref
                .read(mediaServiceProvider)
                .convertAssetIdsToMediaFiles(ref, mediaFiles: mediaFiles);

            await ref
                .read(mediaNsfwParallelCheckerProvider.notifier)
                .addMediaListCheck(convertedMediaFiles);
            print('🔥NSFW check call completed successfully');
          } catch (e) {
            print('🔥NSFW check call failed: $e');
          }
        });
      }

      return null;
    }, [mediaCount]);

    // NSFW check for video files
    useEffect(() {
      final videoFile = attachedVideoNotifier.value;
      if (videoFile != null) {
        print('🔥Video NSFW check triggered for: ${videoFile.path}');

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await ref
                .read(mediaNsfwParallelCheckerProvider.notifier)
                .addMediaListCheck([videoFile]);
            print('🔥Video NSFW check completed');
          } catch (e) {
            print('🔥Video NSFW check failed: $e');
          }
        });
      }

      return null;
    }, [attachedVideoNotifier.value]);

    return BackHardwareButtonInterceptor(
      onBackPress: (_) async => textEditorController.document.isEmpty()
          ? context.pop()
          : await showSimpleBottomSheet<void>(
              context: context,
              child: CancelCreationModal(
                title: context.i18n.cancel_creation_post_title,
                onCancel: () => Navigator.of(context).pop(),
              ),
            ),
      child: SheetContent(
        topPadding: 0,
        body: ShowCaseWidget(
          disableMovingAnimation: true,
          disableScaleAnimation: true,
          builder: (context) => Column(
            children: [
              CreatePostAppBar(
                createOption: createOption,
                textEditorController: textEditorController,
              ),
              Expanded(
                child: CreatePostContent(
                  scrollController: scrollController,
                  attachedVideoNotifier: attachedVideoNotifier,
                  parentEvent: parentEvent,
                  textEditorController: textEditorController,
                  createOption: createOption,
                  attachedMediaNotifier: attachedMediaFilesNotifier,
                  attachedMediaLinksNotifier: attachedMediaLinksNotifier,
                  quotedEvent: quotedEvent,
                  textEditorKey: textEditorKey,
                ),
              ),
              CreatePostBottomPanel(
                textEditorController: textEditorController,
                parentEvent: parentEvent,
                quotedEvent: quotedEvent,
                modifiedEvent: modifiedEvent,
                attachedMediaNotifier: attachedMediaFilesNotifier,
                attachedVideoNotifier: attachedVideoNotifier,
                attachedMediaLinksNotifier: attachedMediaLinksNotifier,
                createOption: createOption,
                scrollController: scrollController,
                textEditorKey: textEditorKey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
