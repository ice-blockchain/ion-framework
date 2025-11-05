// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/chat/providers/draft_message_provider.r.dart';
import 'package:ion/app/features/chat/providers/messaging_bottom_bar_state_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_edit_message_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/selected_reply_message_provider.r.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/chat_attach_menu.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/chat_blocked_user_bar.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/chat_input_bar_recording_overlay.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/action_button.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/chat_attachment_menu_switch_button.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/chat_input_bar_camera_button.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/chat_text_field.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/text_message_limit_label.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/services/compressors/audio_compressor.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/main_tab.dart';

const _navBarVerticalPadding = 8.0;

class ChatInputBar extends HookConsumerWidget {
  const ChatInputBar({
    required this.onSubmitted,
    required this.conversationId,
    required this.receiverMasterPubkey,
    super.key,
  });

  final Future<void> Function({String? content, List<MediaFile>? mediaFiles}) onSubmitted;
  final String? conversationId;
  final String receiverMasterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textFieldFocusNode = useFocusNode();
    final textFieldController = useTextEditingController();
    final voiceRecorderController = useRef(RecorderController());

    final editMessage = ref.watch(selectedEditMessageProvider);
    final repliedMessage = ref.watch(selectedReplyMessageProvider);
    final isBlocked =
        ref.watch(isBlockedNotifierProvider(receiverMasterPubkey)).valueOrNull ?? true;

    final isAttachMenuShown = useState<bool>(false);
    final isTogglingBottomView = useRef(false);
    final recordedMediaFile = useState<MediaFile?>(null);
    final isTextLimitReached = useState<bool>(false);
    final hasText = useState<bool>(false);
    final isKeyboardVisible = useState(false);

    useOnInit(
      () {
        if (conversationId != null) {
          final draftMessage = ref.read(draftMessageProvider(conversationId!));
          if (draftMessage != null && draftMessage.isNotEmpty) {
            textFieldController.text = draftMessage;
          }
        }
      },
      [conversationId],
    );

    useEffect(
      () {
        void onTextChanged() {
          hasText.value = textFieldController.text.trim().isNotEmpty;
          if (conversationId != null) {
            ref.read(draftMessageProvider(conversationId!).notifier).draftMessage =
                textFieldController.text;
          }
          isTextLimitReached.value =
              textFieldController.text.length > EncryptedDirectMessageData.textMessageLimit;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          textFieldController.addListener(onTextChanged);
        });
        return () => textFieldController.removeListener(onTextChanged);
      },
      [textFieldController, conversationId],
    );

    useEffect(
      () {
        if (repliedMessage != null) {
          textFieldFocusNode.requestFocus();
        }
        return null;
      },
      [repliedMessage],
    );

    useEffect(
      () {
        if (editMessage != null) {
          textFieldFocusNode.requestFocus();
          textFieldController.text = editMessage.contentDescription;
        } else {
          textFieldController.clear();
        }
        return null;
      },
      [editMessage],
    );

    useEffect(
      () {
        final sub = KeyboardVisibilityController().onChange.listen((visible) {
          isKeyboardVisible.value = visible;
        });
        return sub.cancel;
      },
      [],
    );

    final hideAttachMenu = useCallback(
      () async {
        isTogglingBottomView.value = true;
        isAttachMenuShown.value = false;
        await Future<void>.delayed(const Duration(milliseconds: 300));
        textFieldFocusNode.requestFocus();
        isTogglingBottomView.value = false;
      },
      [isAttachMenuShown, textFieldFocusNode],
    );

    final showAttachMenu = useCallback(
      () async {
        textFieldFocusNode.unfocus();
        if (isKeyboardVisible.value) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
        isAttachMenuShown.value = true;
      },
      [isAttachMenuShown.value, textFieldFocusNode, isKeyboardVisible.value],
    );

    useEffect(
      () {
        Future<void> textFieldFocusListener() async {
          if (isTogglingBottomView.value) return;
          if (textFieldFocusNode.hasFocus && isAttachMenuShown.value) {
            await hideAttachMenu();
          }
        }

        textFieldFocusNode.addListener(textFieldFocusListener);
        return () => textFieldFocusNode.removeListener(textFieldFocusListener);
      },
      [textFieldFocusNode, isAttachMenuShown.value, isTogglingBottomView],
    );

    if (isBlocked) {
      return ChatBlockedUserBar(receiverMasterPubkey: receiverMasterPubkey);
    }

    final bottomPadding = getBottomPadding(context, navBarVerticalPadding: _navBarVerticalPadding);

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        8.s,
        8.s,
        8.s,
        bottomPadding.s + 8.s,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ChatAttachmentMenuSwitchButton(
                    isAttachMenuShown: isAttachMenuShown.value,
                    onTap: () async {
                      if (isTogglingBottomView.value) return;
                      if (isAttachMenuShown.value) {
                        await hideAttachMenu();
                      } else {
                        await showAttachMenu();
                      }
                    },
                  ),
                  SizedBox(width: 6.s),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        if (isAttachMenuShown.value) {
                          await hideAttachMenu();
                          await Future<void>.delayed(const Duration(milliseconds: 300));
                        }

                        textFieldFocusNode.requestFocus();
                      },
                      child: AbsorbPointer(
                        absorbing: isAttachMenuShown.value,
                        child: ChatTextField(
                          textFieldController: textFieldController,
                          textFieldFocusNode: textFieldFocusNode,
                          onSubmitted: onSubmitted,
                        ),
                      ),
                    ),
                  ),
                  if (!hasText.value) ChatInputBarCameraButton(onSubmitted: onSubmitted),
                  ActionButton(
                    textFieldController: textFieldController,
                    recorderController: voiceRecorderController.value,
                    onSubmitted: isTextLimitReached.value
                        ? null
                        : () async {
                            if (recordedMediaFile.value != null) {
                              unawaited(
                                onSubmitted(
                                  content: textFieldController.text,
                                  mediaFiles: [recordedMediaFile.value!],
                                ),
                              );
                            } else {
                              unawaited(onSubmitted(content: textFieldController.text));
                            }
                            textFieldController.clear();
                            recordedMediaFile.value = null;
                          },
                  ),
                ],
              ),
              TextMessageLimitLabel(textEditingController: textFieldController),
              ChatInputBarRecordingOverlay(
                onRecordingFinished: (mediaFile) async {
                  if (recordedMediaFile.value == null) {
                    recordedMediaFile.value = mediaFile;
                  } else {
                    recordedMediaFile.value =
                        await ref.read(audioCompressorProvider).combineAudioFiles([
                      recordedMediaFile.value!,
                      mediaFile,
                    ]);
                  }
                  return recordedMediaFile.value!.path;
                },
                onCancelled: () {
                  ref.invalidate(voiceRecordingActiveStateProvider);
                  voiceRecorderController.value.reset();
                  recordedMediaFile.value = null;
                },
                recorderController: voiceRecorderController.value,
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: !isKeyboardVisible.value && isAttachMenuShown.value
                  ? SizedBox(
                      width: double.infinity,
                      child: ChatAttachMenu(
                        onSubmitted: onSubmitted,
                        receiverPubKey: receiverMasterPubkey,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
