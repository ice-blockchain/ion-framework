// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/create_post/providers/media_nsfw_parallel_checker.m.dart';
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
import 'package:ion/app/features/nsfw/widgets/nsfw_blocked_sheet.dart';
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

    final loading =
        ref.watch(mediaNsfwParallelCheckerProvider.select((state) => state.isFinalCheckInProcess));
    final anotherLoading = useState(false);

    if (loading || anotherLoading.value) {
      return const CircularProgressIndicator();
    }

    return ToolbarSendButton(
      enabled: isSubmitButtonEnabled,
      onPressed: () async {
        if (!shownTooltip.value && selectedTopics.isEmpty) {
          shownTooltip.value = true;
          ref.read(topicTooltipVisibilityNotifierProvider.notifier).show();
          return;
        }
        // Do not set language for replies.
        final language =
            parentEvent == null ? ref.read(selectedEntityLanguageNotifierProvider) : null;
        if (parentEvent == null && language == null) {
          unawaited(EntityLanguageWarningRoute().push<void>(context));
          return;
        }

        anotherLoading.value = true;
        final triggerDateTime = DateTime.now();
        print('🔥Before assetIds to mediafiles! ');
        final filesToUpload = createOption == CreatePostOption.video
            ? mediaFiles
            : await ref
                .read(mediaServiceProvider)
                .convertAssetIdsToMediaFiles(ref, mediaFiles: mediaFiles);
        print('🔥After converting: ${DateTime.now().difference(triggerDateTime).inMilliseconds}ms');

        // NSFW validation: block posting if any selected image is NSFW
        // final isBlocked = await NsfwSubmitGuard.checkAndBlockMediaFiles(ref, filesToUpload);
        // if (isBlocked) return;
        print('💧Checking NSFW🔥');

        print('🔥Before loading: ${DateTime.now().difference(triggerDateTime).inMilliseconds}ms');
        final hasNsfw = await ref
            .read(mediaNsfwParallelCheckerProvider.notifier)
            .getNsfwCheckValueOrWaitUntil();
        anotherLoading.value = false;

        print('💧Has NSFW result: $hasNsfw🔥');
        if (hasNsfw) {
          if (context.mounted) {
            await showNsfwBlockedSheet(context);
          }

          return;
        }

        // return ref.context.pop(true);

        if (context.mounted) {
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
                language: language?.value,
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
                language: language?.value,
              ),
            );
          }

          if (onSubmitted != null) {
            onSubmitted!();
          } else if (context.mounted) {
            ref.context.maybePop(true);
          }
        }
      },
    );
  }
}
