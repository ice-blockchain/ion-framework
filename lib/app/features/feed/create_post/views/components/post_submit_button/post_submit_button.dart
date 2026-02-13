// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/utils/delta_bridge.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/views/pages/error_modal.dart';
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
import 'package:ion/app/features/nsfw/models/nsfw_check_result.f.dart';
import 'package:ion/app/features/nsfw/providers/media_nsfw_checker.r.dart';
import 'package:ion/app/features/nsfw/widgets/nsfw_blocked_sheet.dart';
import 'package:ion/app/features/user/providers/ugc_counter_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/keyboard/keyboard.dart';
import 'package:ion/app/services/logger/logger.dart';
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
    Logger.talker?.debug(
      '[PostSubmitButton] build() called - createOption: $createOption, parentEvent: $parentEvent, modifiedEvent: $modifiedEvent',
    );

    IonConnectEntity? modifiedEntity;
    if (modifiedEvent != null) {
      try {
        Logger.talker
            ?.debug('[PostSubmitButton] Reading modified entity for event: $modifiedEvent');
        modifiedEntity =
            ref.read(ionConnectEntityProvider(eventReference: modifiedEvent!)).valueOrNull;
        Logger.talker?.debug(
          '[PostSubmitButton] Modified entity read: ${modifiedEntity != null ? "found" : "null"}',
        );
      } catch (e, st) {
        Logger.error(
          e,
          stackTrace: st,
          message: '[PostSubmitButton] Failed to read modified entity',
        );
      }
    }

    final draftPoll = ref.watch(pollDraftNotifierProvider);
    final whoCanReply = ref.watch(selectedWhoCanReplyOptionProvider);
    final selectedTopics = ref.watch(selectedInterestsNotifierProvider);
    final shownTooltip = useRef(!shouldShowTooltip);

    Logger.talker?.debug(
      '[PostSubmitButton] State check - draftPoll.added: ${draftPoll.added}, '
      'selectedTopics: ${selectedTopics.length}, shownTooltip: ${shownTooltip.value}, '
      'whoCanReply: $whoCanReply',
    );

    final isSubmitButtonEnabled = useCanSubmitPost(
      textEditorController: textEditorController,
      mediaFiles: mediaFiles,
      mediaAttachments: mediaAttachments,
      hasPoll: draftPoll.added,
      pollAnswers: draftPoll.answers,
      modifiedEvent: modifiedEntity,
    );

    Logger.talker?.debug('[PostSubmitButton] isSubmitButtonEnabled: $isSubmitButtonEnabled');

    final loading = useState(false);
    final prefetchedUgcCounter = ref.watch(ugcCounterProvider());

    Logger.talker?.debug(
      '[PostSubmitButton] prefetchedUgcCounter state: ${prefetchedUgcCounter.isLoading ? "loading" : prefetchedUgcCounter.hasValue ? "value: ${prefetchedUgcCounter.value}" : "error"}',
    );

    // Log state changes
    useEffect(() {
      Logger.talker?.debug(
        '[PostSubmitButton] State changed - enabled: $isSubmitButtonEnabled, '
        'loading: ${loading.value}, selectedTopics: ${selectedTopics.length}',
      );
      return null;
    }, [isSubmitButtonEnabled, loading.value, selectedTopics.length],);

    // Log when button becomes enabled/disabled
    useEffect(() {
      Logger.talker?.debug(
        '[PostSubmitButton] Button enabled state: $isSubmitButtonEnabled',
      );
      return null;
    }, [isSubmitButtonEnabled],);

    // Log when loading state changes
    useEffect(() {
      Logger.talker?.debug('[PostSubmitButton] Loading state changed: ${loading.value}');
      return null;
    }, [loading.value],);

    return ToolbarSendButton(
      enabled: isSubmitButtonEnabled,
      loading: loading.value,
      onPressed: () async {
        Logger.talker?.debug(
          '[PostSubmitButton] onPressed() called - enabled: $isSubmitButtonEnabled, loading: ${loading.value}',
        );

        try {
          Logger.talker?.debug('[PostSubmitButton] Step 1: Hiding keyboard');
          hideKeyboard(context);

          Logger.talker?.debug(
            '[PostSubmitButton] Step 2: Checking topics - shownTooltip: ${shownTooltip.value}, '
            'selectedTopics.isEmpty: ${selectedTopics.isEmpty}',
          );

          if (!shownTooltip.value && selectedTopics.isEmpty) {
            Logger.talker
                ?.debug('[PostSubmitButton] Topics empty - showing tooltip and returning early');
            try {
              shownTooltip.value = true;
              ref.read(topicTooltipVisibilityNotifierProvider.notifier).show();
              Logger.talker?.debug('[PostSubmitButton] Topic tooltip shown successfully');
            } catch (e, st) {
              Logger.error(
                e,
                stackTrace: st,
                message: '[PostSubmitButton] Failed to show topic tooltip',
              );
            }
            return;
          }

          Logger.talker
              ?.debug('[PostSubmitButton] Step 3: Checking language - parentEvent: $parentEvent');

          // Do not set language for replies.
          String? languageValue;
          try {
            final language =
                parentEvent == null ? ref.read(selectedEntityLanguageNotifierProvider) : null;
            languageValue = language?.value;
            Logger.talker?.debug(
              '[PostSubmitButton] Language check - parentEvent == null: ${parentEvent == null}, '
              'language: $languageValue',
            );
          } catch (e, st) {
            Logger.error(
              e,
              stackTrace: st,
              message: '[PostSubmitButton] Failed to read language',
            );
          }

          if (parentEvent == null && languageValue == null) {
            Logger.talker?.debug(
              '[PostSubmitButton] Language not set - pushing warning route and returning early',
            );
            try {
              unawaited(EntityLanguageWarningRoute().push<void>(context));
              Logger.talker?.debug('[PostSubmitButton] Language warning route pushed');
            } catch (e, st) {
              Logger.error(
                e,
                stackTrace: st,
                message: '[PostSubmitButton] Failed to push language warning route',
              );
            }
            return;
          }

          Logger.talker?.debug('[PostSubmitButton] Step 4: Setting loading state to true');
          loading.value = true;

          try {
            Logger.talker?.debug(
              '[PostSubmitButton] Step 5: Preparing files - createOption: $createOption, '
              'mediaFiles.length: ${mediaFiles.length}',
            );

            List<MediaFile> filesToUpload;
            try {
              if (createOption == CreatePostOption.video) {
                Logger.talker?.debug('[PostSubmitButton] Using video files directly');
                filesToUpload = mediaFiles;
              } else {
                Logger.talker?.debug('[PostSubmitButton] Converting asset IDs to media files');
                filesToUpload = await ref
                    .read(mediaServiceProvider)
                    .convertAssetIdsToMediaFiles(ref, mediaFiles: mediaFiles);
                Logger.talker
                    ?.debug('[PostSubmitButton] Converted files count: ${filesToUpload.length}');
              }
            } catch (e, st) {
              Logger.error(
                e,
                stackTrace: st,
                message: '[PostSubmitButton] Failed to prepare files for upload',
              );
              rethrow;
            }

            Logger.talker
                ?.debug('[PostSubmitButton] Step 6: Checking context.mounted after file prep');
            if (!context.mounted) {
              Logger.talker
                  ?.debug('[PostSubmitButton] Context unmounted after file prep - returning early');
              return;
            }

            Logger.talker?.debug('[PostSubmitButton] Step 7: Getting NSFW checker');
            MediaNsfwChecker mediaChecker;
            try {
              mediaChecker = await ref.read(mediaNsfwCheckerProvider.future);
              Logger.talker?.debug('[PostSubmitButton] NSFW checker obtained');
            } catch (e, st) {
              Logger.error(
                e,
                stackTrace: st,
                message: '[PostSubmitButton] Failed to get NSFW checker',
              );
              rethrow;
            }

            Logger.talker?.debug('[PostSubmitButton] Step 8: Checking media for NSFW');
            try {
              await mediaChecker.checkMediaForNsfw(filesToUpload);
              Logger.talker?.debug('[PostSubmitButton] NSFW check completed');
            } catch (e, st) {
              Logger.error(
                e,
                stackTrace: st,
                message: '[PostSubmitButton] Failed to check media for NSFW',
              );
              rethrow;
            }

            Logger.talker?.debug('[PostSubmitButton] Step 9: Getting NSFW check result');
            NsfwCheckResult nsfwCheckResult;
            try {
              nsfwCheckResult = await mediaChecker.hasNsfwMedia();
              Logger.talker
                  ?.debug('[PostSubmitButton] NSFW check result: ${nsfwCheckResult.runtimeType}');
            } catch (e, st) {
              Logger.error(
                e,
                stackTrace: st,
                message: '[PostSubmitButton] Failed to get NSFW check result',
              );
              rethrow;
            }

            Logger.talker
                ?.debug('[PostSubmitButton] Step 10: Checking context.mounted after NSFW check');
            if (!context.mounted) {
              Logger.talker?.debug(
                '[PostSubmitButton] Context unmounted after NSFW check - returning early',
              );
              return;
            }

            Logger.talker?.debug('[PostSubmitButton] Step 11: Validating NSFW result');
            if (nsfwCheckResult is NsfwFailure) {
              Logger.talker?.debug('[PostSubmitButton] NSFW check failed - showing error modal');
              try {
                showErrorModal(context, NSFWProcessingException());
              } catch (e, st) {
                Logger.error(
                  e,
                  stackTrace: st,
                  message: '[PostSubmitButton] Failed to show NSFW error modal',
                );
              }
              return;
            }

            // NSFW validation: block posting if any selected image is NSFW
            if (nsfwCheckResult is NsfwSuccess && nsfwCheckResult.hasNsfw) {
              Logger.talker
                  ?.debug('[PostSubmitButton] NSFW content detected - showing blocked sheet');
              if (context.mounted) {
                try {
                  await showNsfwBlockedSheet(context);
                  Logger.talker?.debug('[PostSubmitButton] NSFW blocked sheet shown');
                } catch (e, st) {
                  Logger.error(
                    e,
                    stackTrace: st,
                    message: '[PostSubmitButton] Failed to show NSFW blocked sheet',
                  );
                }
              }
              return;
            }

            Logger.talker?.debug(
              '[PostSubmitButton] Step 12: Checking context.mounted before post creation',
            );
            if (!context.mounted) {
              Logger.talker?.debug(
                '[PostSubmitButton] Context unmounted before post creation - returning early',
              );
              return;
            }

            Logger.talker?.debug('[PostSubmitButton] Step 13: Getting create post notifier');
            CreatePostNotifier notifier;
            try {
              notifier = ref.read(createPostNotifierProvider(createOption).notifier);
              Logger.talker?.debug('[PostSubmitButton] Notifier obtained');
            } catch (e, st) {
              Logger.error(
                e,
                stackTrace: st,
                message: '[PostSubmitButton] Failed to get create post notifier',
              );
              rethrow;
            }

            Logger.talker?.debug(
              '[PostSubmitButton] Step 14: Preparing post data - modifiedEvent: $modifiedEvent, '
              'topics: ${selectedTopics.length}, language: $languageValue',
            );

            try {
              final contentDelta = DeltaBridge.normalizeToAttributeFormat(
                textEditorController.document.toDelta(),
              );
              Logger.talker?.debug('[PostSubmitButton] Content delta normalized');

              if (modifiedEvent != null) {
                Logger.talker?.debug('[PostSubmitButton] Step 15a: Calling modify()');
                try {
                  unawaited(
                    notifier.modify(
                      content: contentDelta,
                      mediaFiles: filesToUpload,
                      mediaAttachments: mediaAttachments,
                      eventReference: modifiedEvent!,
                      whoCanReply: whoCanReply,
                      topics: selectedTopics,
                      poll: PollUtils.pollDraftToPollData(draftPoll),
                      language: languageValue,
                    ),
                  );
                  Logger.talker?.debug('[PostSubmitButton] modify() called successfully');
                } catch (e, st) {
                  Logger.error(
                    e,
                    stackTrace: st,
                    message: '[PostSubmitButton] Failed to call modify()',
                  );
                  rethrow;
                }
              } else {
                Logger.talker?.debug('[PostSubmitButton] Step 15b: Calling create()');
                Logger.talker?.debug(
                  '[PostSubmitButton] Create params - parentEvent: $parentEvent, '
                  'quotedEvent: $quotedEvent, filesToUpload: ${filesToUpload.length}, '
                  'ugcCounter: ${prefetchedUgcCounter.value}',
                );

                try {
                  unawaited(
                    notifier.create(
                      content: contentDelta,
                      parentEvent: parentEvent,
                      quotedEvent: quotedEvent,
                      mediaFiles: filesToUpload,
                      whoCanReply: whoCanReply,
                      topics: selectedTopics,
                      poll: PollUtils.pollDraftToPollData(draftPoll),
                      language: languageValue,
                      ugcCounter: prefetchedUgcCounter.value,
                    ),
                  );
                  Logger.talker?.debug('[PostSubmitButton] create() called successfully');
                } catch (e, st) {
                  Logger.error(
                    e,
                    stackTrace: st,
                    message: '[PostSubmitButton] Failed to call create()',
                  );
                  rethrow;
                }
              }

              Logger.talker?.debug('[PostSubmitButton] Step 16: Handling post-submit callback');
              if (onSubmitted != null) {
                Logger.talker?.debug('[PostSubmitButton] Calling onSubmitted callback');
                try {
                  onSubmitted!();
                  Logger.talker?.debug('[PostSubmitButton] onSubmitted callback completed');
                } catch (e, st) {
                  Logger.error(
                    e,
                    stackTrace: st,
                    message: '[PostSubmitButton] onSubmitted callback failed',
                  );
                }
              } else if (context.mounted) {
                Logger.talker?.debug('[PostSubmitButton] Popping context');
                try {
                  ref.context.maybePop(true);
                  Logger.talker?.debug('[PostSubmitButton] Context popped');
                } catch (e, st) {
                  Logger.error(
                    e,
                    stackTrace: st,
                    message: '[PostSubmitButton] Failed to pop context',
                  );
                }
              } else {
                Logger.talker?.debug('[PostSubmitButton] Context not mounted, skipping pop');
              }
            } catch (e, st) {
              Logger.error(
                e,
                stackTrace: st,
                message: '[PostSubmitButton] Failed to prepare or submit post data',
              );
              rethrow;
            }
          } catch (e, st) {
            Logger.error(
              e,
              stackTrace: st,
              message: '[PostSubmitButton] Error during post submission process',
            );
            rethrow;
          } finally {
            Logger.talker
                ?.debug('[PostSubmitButton] Step 17: Finally block - checking context.mounted');
            if (context.mounted) {
              Logger.talker?.debug('[PostSubmitButton] Setting loading state to false');
              loading.value = false;
              Logger.talker?.debug('[PostSubmitButton] Loading state set to false');
            } else {
              Logger.talker
                  ?.debug('[PostSubmitButton] Context not mounted, skipping loading state update');
            }
          }
        } catch (e, st) {
          Logger.error(
            e,
            stackTrace: st,
            message: '[PostSubmitButton] Unhandled error in onPressed handler',
          );
        }
      },
    );
  }
}
