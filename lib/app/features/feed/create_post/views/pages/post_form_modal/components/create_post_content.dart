// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separated_row.dart';
import 'package:ion/app/components/text_editor/text_editor.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/create_post/views/components/language_button/language_button.dart';
import 'package:ion/app/features/feed/create_post/views/components/reply_input_field/attached_media_preview.dart';
import 'package:ion/app/features/feed/create_post/views/components/topics_button/topics_button.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/components/current_user_avatar.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/components/parent_entity.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/components/quoted_entity.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/components/video_preview_cover.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/hooks/use_url_links.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/polls/providers/poll_draft_provider.r.dart';
import 'package:ion/app/features/feed/polls/view/components/poll.dart';
import 'package:ion/app/features/feed/views/components/url_preview_content/url_preview_content.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/typedefs/typedefs.dart';

class CreatePostContent extends StatelessWidget {
  const CreatePostContent({
    required this.scrollController,
    required this.attachedVideoNotifier,
    required this.parentEvent,
    required this.textEditorController,
    required this.createOption,
    required this.attachedMediaNotifier,
    required this.attachedMediaLinksNotifier,
    required this.quotedEvent,
    required this.textEditorKey,
    super.key,
  });

  final ScrollController scrollController;
  final ValueNotifier<MediaFile?> attachedVideoNotifier;
  final EventReference? parentEvent;
  final QuillController textEditorController;
  final CreatePostOption createOption;
  final AttachedMediaNotifier attachedMediaNotifier;
  final AttachedMediaLinksNotifier attachedMediaLinksNotifier;
  final EventReference? quotedEvent;
  final GlobalKey<TextEditorState> textEditorKey;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VideoPreviewSection(attachedVideoNotifier: attachedVideoNotifier),
          // Taking topics from the parent event, do not set language for replies.
          if (parentEvent == null)
            _HeaderControls(
              children: [
                // Taking topics from the quoted event.
                if (quotedEvent == null)
                  _TopicsButton(
                    attachedMediaNotifier: attachedMediaNotifier,
                    attachedVideoNotifier: attachedVideoNotifier,
                    attachedMediaLinksNotifier: attachedMediaLinksNotifier,
                    parentEvent: parentEvent,
                    quotedEvent: quotedEvent,
                  ),
                LanguageButton(createOption: createOption),
              ],
            ),
          if (parentEvent != null) _ParentEntitySection(eventReference: parentEvent!),
          _TextInputSection(
            textEditorController: textEditorController,
            createOption: createOption,
            attachedMediaNotifier: attachedMediaNotifier,
            attachedMediaLinksNotifier: attachedMediaLinksNotifier,
            textEditorKey: textEditorKey,
            scrollController: scrollController,
          ),
          if (quotedEvent != null) _QuotedEntitySection(eventReference: quotedEvent!),
        ],
      ),
    );
  }
}

class _VideoPreviewSection extends StatelessWidget {
  const _VideoPreviewSection({
    required this.attachedVideoNotifier,
  });

  final ValueNotifier<MediaFile?> attachedVideoNotifier;

  @override
  Widget build(BuildContext context) {
    return ScreenSideOffset.small(
      child: Center(
        child: VideoPreviewCover(attachedVideoNotifier: attachedVideoNotifier),
      ),
    );
  }
}

class _ParentEntitySection extends StatelessWidget {
  const _ParentEntitySection({
    required this.eventReference,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context) {
    return ScreenSideOffset.small(
      child: IgnorePointer(
        child: ParentEntity(eventReference: eventReference),
      ),
    );
  }
}

class _TextInputSection extends HookConsumerWidget {
  const _TextInputSection({
    required this.textEditorController,
    required this.createOption,
    required this.attachedMediaNotifier,
    required this.attachedMediaLinksNotifier,
    required this.textEditorKey,
    required this.scrollController,
  });

  final QuillController textEditorController;
  final CreatePostOption createOption;
  final AttachedMediaNotifier attachedMediaNotifier;
  final AttachedMediaLinksNotifier attachedMediaLinksNotifier;
  final GlobalKey<TextEditorState> textEditorKey;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaFiles = attachedMediaNotifier.value;
    final mediaLinks = attachedMediaLinksNotifier.value.values.toList();
    final draftPoll = ref.watch(pollDraftNotifierProvider);

    final links = useUrlLinks(
      textEditorController: textEditorController,
      mediaFiles: mediaFiles,
    );

    useEffect(
      () {
        final keyboardVisibilityController = KeyboardVisibilityController();
        final subscription = keyboardVisibilityController.onChange.listen((isVisible) {
          if (isVisible) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (textEditorKey.currentContext != null) {
                Scrollable.ensureVisible(
                  textEditorKey.currentContext!,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
        });
        return subscription.cancel;
      },
      [],
    );

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 10.0.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: ScreenSideOffset.defaultSmallMargin,
            ),
            child: const CurrentUserAvatar(),
          ),
          SizedBox(width: 10.0.s),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                top: 6.0.s,
                end: ScreenSideOffset.defaultSmallMargin,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: textEditorController,
                    builder: (context, _) {
                      final isEmpty = textEditorController.document.toPlainText().trim().isEmpty;
                      return Stack(
                        children: [
                          TextEditor(
                            textEditorController,
                            key: textEditorKey,
                            placeholder: '',
                            scrollController: scrollController,
                          ),
                          if (isEmpty)
                            IgnorePointer(
                              child: Text(
                                createOption.getPlaceholder(context),
                                style: context.theme.appTextThemes.body2.copyWith(
                                  color: context.theme.appColors.tertiaryText,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (draftPoll.added) ...[
                    SizedBox(height: 12.0.s),
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: 23.0.s),
                      child: Poll(
                        onRemove: () {
                          ref.read(pollDraftNotifierProvider.notifier).reset();
                        },
                      ),
                    ),
                  ],
                  if (mediaFiles.isNotEmpty || mediaLinks.isNotEmpty) ...[
                    SizedBox(height: 12.0.s),
                    AttachedMediaPreview(
                      attachedMediaNotifier: attachedMediaNotifier,
                      attachedMediaLinksNotifier: attachedMediaLinksNotifier,
                    ),
                  ],
                  if (mediaFiles.isEmpty && links.isNotEmpty)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        top: 10.0.s,
                      ),
                      child: UrlPreviewContent(
                        url: links.first,
                        clickable: false,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotedEntitySection extends StatelessWidget {
  const _QuotedEntitySection({
    required this.eventReference,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context) {
    return ScreenSideOffset.small(
      child: IgnorePointer(
        child: QuotedEntity(eventReference: eventReference),
      ),
    );
  }
}

class _HeaderControls extends StatelessWidget {
  const _HeaderControls({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ScreenSideOffset.small(
        child: Padding(
          padding: EdgeInsetsDirectional.only(bottom: 8.s),
          child: SeparatedRow(
            separator: SizedBox(width: 8.s),
            children: children,
          ),
        ),
      ),
    );
  }
}

class _TopicsButton extends HookConsumerWidget {
  const _TopicsButton({
    required this.attachedMediaNotifier,
    required this.attachedVideoNotifier,
    required this.attachedMediaLinksNotifier,
    required this.parentEvent,
    required this.quotedEvent,
  });

  final AttachedMediaNotifier attachedMediaNotifier;
  final ValueNotifier<MediaFile?> attachedVideoNotifier;
  final AttachedMediaLinksNotifier attachedMediaLinksNotifier;
  final EventReference? parentEvent;
  final EventReference? quotedEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnyMediaVideo = attachedMediaNotifier.value.any(
      (media) {
        final mediaType = MediaType.fromMimeType(media.mimeType.emptyOrValue);
        return mediaType == MediaType.video;
      },
    );
    final isAnyMediaLinkVideo = attachedMediaLinksNotifier.value.values.any(
      (mediaLink) {
        return mediaLink.mediaType == MediaType.video;
      },
    );
    final isVideo = attachedVideoNotifier.value != null || isAnyMediaVideo || isAnyMediaLinkVideo;

    return TopicsButton(type: isVideo ? FeedType.video : FeedType.post);
  }
}
