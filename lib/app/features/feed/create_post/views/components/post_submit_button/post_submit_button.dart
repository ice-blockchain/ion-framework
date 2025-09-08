// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/create_post/views/hooks/use_can_submit_post.dart';
import 'package:ion/app/features/feed/polls/providers/poll_draft_provider.r.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_send_button.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion_content_labeler/ion_content_labeler.dart';

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
    // final whoCanReply = ref.watch(selectedWhoCanReplyOptionProvider);
    // final selectedTopics = ref.watch(selectedInterestsNotifierProvider);
    // final shownTooltip = useRef(!shouldShowTooltip);

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
        /// [START] Content labeler test
        final input = textEditorController.document.toPlainText();
        final result = await IONTextLabeler().detect(input, model: TextLabelerModel.language);
        if (context.mounted) {
          await showSimpleBottomSheet<void>(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text('Languages:\n${result.labels.join(',\n')}'),
                const SizedBox(height: 20),
                Text('Normalized Input:\n${result.input}'),
                const SizedBox(height: 50),
              ],
            ),
          );
        }

        /// [END] Content labeler test
      },
    );
  }
}
