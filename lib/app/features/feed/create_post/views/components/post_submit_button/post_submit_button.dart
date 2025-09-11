// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/create_post/views/hooks/use_can_submit_post.dart';
import 'package:ion/app/features/feed/polls/providers/poll_draft_provider.r.dart';
import 'package:ion/app/features/feed/polls/utils/poll_utils.dart';
import 'package:ion/app/features/feed/providers/selected_entity_language_notifier.r.dart';
import 'package:ion/app/features/feed/providers/selected_interests_notifier.r.dart';
import 'package:ion/app/features/feed/providers/selected_who_can_reply_option_provider.r.dart';
import 'package:ion/app/features/feed/providers/topic_tooltip_visibility_notifier.r.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_send_button.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class PostSubmitButton extends HookConsumerWidget {
  const PostSubmitButton({
    required this.textEditorController,
    required this.createOption,
    super.key,
    this.parentEvent,
    this.quotedEvent,
    this.modifiedEvent,
    this.mediaFiles = const [],
    this.mediaAttachments = const {},
    this.onSubmitted,
    this.shouldShowTooltip = true,
  });

  final QuillController textEditorController;

  final EventReference? parentEvent;

  final EventReference? quotedEvent;

  final EventReference? modifiedEvent;

  final List<MediaFile> mediaFiles;

  final Map<String, MediaAttachment> mediaAttachments;

  final CreatePostOption createOption;

  final VoidCallback? onSubmitted;

  final bool shouldShowTooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IonConnectEntity? modifiedEntity;
    if (modifiedEvent != null) {
      modifiedEntity =
          ref.read(ionConnectEntityProvider(eventReference: modifiedEvent!)).valueOrNull;
    }
    final draftPoll = ref.watch(pollDraftNotifierProvider);
    final whoCanReply = ref.watch(selectedWhoCanReplyOptionProvider);
    final selectedTopics = ref.watch(selectedInterestsNotifierProvider);
    final shownTooltip = useRef(!shouldShowTooltip);

    final isSubmitButtonEnabled = useCanSubmitPost(
      textEditorController: textEditorController,
      mediaFiles: mediaFiles,
      mediaAttachments: mediaAttachments,
      hasPoll: draftPoll.added,
      pollAnswers: draftPoll.answers,
      modifiedEvent: modifiedEntity,
    );

    return ToolbarSendButton(
      enabled: isSubmitButtonEnabled,
      onPressed: () async {
        if (!shownTooltip.value && selectedTopics.isEmpty) {
          shownTooltip.value = true;
          ref.read(topicTooltipVisibilityNotifierProvider.notifier).show();
          return;
        }

        if (ref.read(selectedEntityLanguageNotifierProvider) == null) {
          await EntityLanguageWarningRoute().push<void>(context);
          if (ref.read(selectedEntityLanguageNotifierProvider) == null) {
            return;
          }
        }

        final filesToUpload = createOption == CreatePostOption.video
            ? mediaFiles
            : await ref
                .read(mediaServiceProvider)
                .convertAssetIdsToMediaFiles(ref, mediaFiles: mediaFiles);

        final notifier = ref.read(createPostNotifierProvider(createOption).notifier);

        if (modifiedEvent != null) {
          unawaited(
            notifier.modify(
              content: textEditorController.document.toDelta(),
              mediaFiles: filesToUpload,
              mediaAttachments: mediaAttachments,
              eventReference: modifiedEvent!,
              whoCanReply: whoCanReply,
              topics: selectedTopics,
              poll: PollUtils.pollDraftToPollData(draftPoll),
            ),
          );
        } else {
          unawaited(
            notifier.create(
              content: textEditorController.document.toDelta(),
              parentEvent: parentEvent,
              quotedEvent: quotedEvent,
              mediaFiles: filesToUpload,
              whoCanReply: whoCanReply,
              topics: selectedTopics,
              poll: PollUtils.pollDraftToPollData(draftPoll),
            ),
          );
        }

        if (onSubmitted != null) {
          onSubmitted!();
        } else if (context.mounted) {
          ref.context.pop(true);
        }
      },
    );
  }
}
