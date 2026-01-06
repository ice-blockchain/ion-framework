// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/hooks/use_node_focused.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/text_editor/components/suggestions_container.dart';
import 'package:ion/app/components/text_editor/hooks/use_quill_controller.dart';
import 'package:ion/app/components/text_editor/text_editor.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/create_post/views/components/character_limit_exceed_indicator/character_limit_exceed_indicator.dart';
import 'package:ion/app/features/feed/create_post/views/components/post_submit_button/post_submit_button.dart';
import 'package:ion/app/features/feed/create_post/views/components/reply_input_field/attached_media_preview.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/views/components/actions_toolbar/actions_toolbar.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_bold_button.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_image_button.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_italic_button.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_poll_button.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tooltip/hooks/use_show_tooltip_overlay.dart';
import 'package:ion/app/features/tooltip/views/tooltip.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class TokenCommentInputField extends HookConsumerWidget {
  const TokenCommentInputField({
    required this.tokenDefinition,
    this.onFocusChanged,
    super.key,
  });

  final CommunityTokenDefinitionEntity tokenDefinition;
  final ValueChanged<bool>? onFocusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textEditorController = useQuillController();
    final textEditorKey = useMemoized(TextEditorKeys.replyInput);
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);

    final externalAddress = tokenDefinition.data.externalAddress;
    final tokenInfo = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;
    final isHolder = tokenInfo?.marketData.position != null;

    final inputContainerKey = useRef(GlobalKey());
    final focusNode = useFocusNode();
    final hasFocus = useNodeFocused(focusNode);
    final attachedMediaNotifier = useState(<MediaFile>[]);
    final attachedMediaLinksNotifier = useState<Map<String, MediaAttachment>>({});
    final scrollController = useScrollController();

    final showTooltipOverlay = useShowTooltipOverlay(
      targetKey: inputContainerKey.value,
      text: context.i18n.token_comment_holders_only,
      pointerPosition: TooltipPointerPosition.topLeft,
      position: TooltipPosition.bottom,
      horizontalPadding: 16,
    );

    useEffect(
      () {
        onFocusChanged?.call(hasFocus.value);
        return null;
      },
      [hasFocus.value],
    );

    void handleInputTap() {
      if (!isHolder) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showTooltipOverlay();
        });
      } else {
        focusNode.requestFocus();
      }
    }

    return ScreenSideOffset.small(
      child: TextFieldTapRegion(
        onTapOutside: (_) {
          focusNode.unfocus();
        },
        child: Column(
          children: [
            SuggestionsContainer(
              scrollController: scrollController,
              editorKey: textEditorKey,
            ),
            SizedBox(height: 12.0.s),
            Row(
              children: [
                if (!hasFocus.value && currentPubkey != null)
                  Padding(
                    key: inputContainerKey.value,
                    padding: EdgeInsetsDirectional.only(end: 6.0.s),
                    child: Opacity(
                      opacity: isHolder ? 1.0 : 0.5,
                      child: IonConnectAvatar(
                        masterPubkey: currentPubkey,
                        size: 36.0.s,
                        borderRadius: BorderRadius.all(Radius.circular(12.0.s)),
                      ),
                    ),
                  ),
                Expanded(
                  child: GestureDetector(
                    onTap: handleInputTap,
                    child: Opacity(
                      opacity: isHolder ? 1.0 : 0.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.theme.appColors.onSecondaryBackground,
                          borderRadius: BorderRadius.circular(16.0.s),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (attachedMediaNotifier.value.isNotEmpty) ...[
                              SizedBox(height: 6.0.s),
                              Row(
                                children: [
                                  SizedBox(width: 12.0.s),
                                  Expanded(
                                    child: AttachedMediaPreview(
                                      attachedMediaNotifier: attachedMediaNotifier,
                                      attachedMediaLinksNotifier: attachedMediaLinksNotifier,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.0.s, vertical: 9.0.s),
                              constraints: BoxConstraints(
                                maxHeight: 68.0.s,
                                minHeight: 36.0.s,
                              ),
                              child: AbsorbPointer(
                                absorbing: !isHolder,
                                child: TextEditor(
                                  textEditorController,
                                  focusNode: focusNode,
                                  autoFocus: false,
                                  placeholder: context.i18n.feed_write_comment,
                                  key: textEditorKey,
                                  scrollable: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.0.s),
            if (hasFocus.value && isHolder)
              ActionsToolbar(
                actions: [
                  ToolbarMediaButton(
                    delegate: AttachedMediaHandler(attachedMediaNotifier),
                    maxMedia: ModifiablePostEntity.contentMediaLimit,
                  ),
                  const ToolbarPollButton(),
                  ToolbarItalicButton(textEditorController: textEditorController),
                  ToolbarBoldButton(textEditorController: textEditorController),
                ],
                trailing: Row(
                  children: [
                    CharacterLimitExceedIndicator(
                      maxCharacters: ModifiablePostEntity.contentCharacterLimit,
                      textEditorController: textEditorController,
                    ),
                    SizedBox(width: 8.0.s),
                    PostSubmitButton(
                      textEditorController: textEditorController,
                      parentEvent: tokenDefinition.toEventReference(),
                      mediaFiles: attachedMediaNotifier.value,
                      createOption: CreatePostOption.reply,
                      shouldShowTooltip: false,
                      onSubmitted: () {
                        _clear(
                          focusNode: focusNode,
                          attachedMediaNotifier: attachedMediaNotifier,
                          textEditorController: textEditorController,
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _clear({
    required FocusNode focusNode,
    required ValueNotifier<List<MediaFile>> attachedMediaNotifier,
    required QuillController textEditorController,
  }) {
    focusNode.unfocus();
    attachedMediaNotifier.value = [];

    /// calling `.replaceText` instead of `.clear` due to missing `ignoreFocus` parameter.
    textEditorController.replaceText(
      0,
      textEditorController.plainTextEditingValue.text.length - 1,
      '',
      const TextSelection.collapsed(offset: 0),
      ignoreFocus: true,
    );
  }
}
