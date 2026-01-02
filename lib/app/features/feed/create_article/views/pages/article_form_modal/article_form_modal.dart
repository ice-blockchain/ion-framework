// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/back_hardware_button_interceptor/back_hardware_button_interceptor.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/inputs/text_input/ion_text_field.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/components/text_editor/components/suggestions_container.dart';
import 'package:ion/app/components/text_editor/hooks/use_process_mention_embeds.dart';
import 'package:ion/app/components/text_editor/text_editor.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/create_article/views/pages/article_form_modal/components/article_form_add_image.dart';
import 'package:ion/app/features/feed/create_article/views/pages/article_form_modal/components/article_form_toolbar.dart';
import 'package:ion/app/features/feed/create_article/views/pages/article_form_modal/hooks/use_article_form.dart';
import 'package:ion/app/features/feed/hooks/use_cancel_creation_modal.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/services/keyboard/keyboard.dart';

class ArticleFormModal extends HookConsumerWidget {
  factory ArticleFormModal({
    Key? key,
  }) = ArticleFormModal.create;

  const ArticleFormModal._({
    super.key,
    this.modifiedEvent,
  });

  factory ArticleFormModal.create({
    Key? key,
  }) {
    return ArticleFormModal._(
      key: key,
    );
  }

  factory ArticleFormModal.edit({
    required EventReference modifiedEvent,
    Key? key,
  }) {
    return ArticleFormModal._(
      key: key,
      modifiedEvent: modifiedEvent,
    );
  }

  final EventReference? modifiedEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleState = useArticleForm(ref, modifiedEvent: modifiedEvent);
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);

    // Process mention embeds reactively (handles both upgrades and downgrades)
    useProcessMentionEmbeds(articleState.textEditorController, ref);

    final scrollController = ScrollController();
    final textEditorKey = useMemoized(TextEditorKeys.createArticle);
    final textEditorFocusNode = useFocusNode();
    final restorationFocusNodeRef = useRef<FocusNode?>(null);

    // Track which focus node is currently focused
    useEffect(
      () {
        void onTitleFocusChange() {
          if (articleState.titleFocusNode.hasFocus) {
            restorationFocusNodeRef.value = articleState.titleFocusNode;
          }
        }

        void onEditorFocusChange() {
          if (textEditorFocusNode.hasFocus) {
            restorationFocusNodeRef.value = textEditorFocusNode;
          }
        }

        articleState.titleFocusNode.addListener(onTitleFocusChange);
        textEditorFocusNode.addListener(onEditorFocusChange);

        return () {
          articleState.titleFocusNode.removeListener(onTitleFocusChange);
          textEditorFocusNode.removeListener(onEditorFocusChange);
        };
      },
      [articleState.titleFocusNode, textEditorFocusNode],
    );

    final onAttemptToCancel = useCancelCreationModal(
      title: context.i18n.cancel_creation_article_title,
      textEditorController: articleState.textEditorController,
    );

    return BackHardwareButtonInterceptor(
      onBackPress: (context) async {
        hideKeyboard(context);
        await onAttemptToCancel();
      },
      child: SheetContent(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              title: Text(
                modifiedEvent != null
                    ? context.i18n.create_article_nav_title_edit
                    : context.i18n.create_article_nav_title,
              ),
              onBackPress: () {
                hideKeyboard(context);
                onAttemptToCancel();
              },
              actions: [
                Button(
                  type: ButtonType.secondary,
                  label: Text(
                    context.i18n.button_next,
                    style: context.theme.appTextThemes.body.copyWith(
                      color: articleState.isButtonEnabled
                          ? context.theme.appColors.primaryAccent
                          : context.theme.appColors.sheetLine,
                    ),
                  ),
                  backgroundColor: context.theme.appColors.secondaryBackground,
                  borderColor: context.theme.appColors.secondaryBackground,
                  disabled: !articleState.isButtonEnabled,
                  onPressed: () async {
                    hideKeyboard(context);
                    articleState.onNext();
                    if (modifiedEvent != null) {
                      final eventEncoded = modifiedEvent!.encode();
                      await EditArticlePreviewRoute(modifiedEvent: eventEncoded)
                          .push<void>(context);
                    } else {
                      await ArticlePreviewRoute().push<void>(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          context.maybePop();
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    ArticleFormAddImage(
                      selectedImage: articleState.selectedImage,
                      selectedImageUrl: articleState.selectedImageUrl,
                      restorationFocusNode: restorationFocusNodeRef.value,
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: ScreenSideOffset.defaultSmallMargin,
                        end: ScreenSideOffset.defaultSmallMargin,
                        top: ScreenSideOffset.defaultSmallMargin,
                      ),
                      child: IonTextField(
                        controller: articleState.titleController,
                        focusNode: articleState.titleFocusNode,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        maxLines: null,
                        onSubmitted: (_) {
                          articleState.editorFocusNotifier.value = true;
                        },
                        style: context.theme.appTextThemes.headline2.copyWith(
                          color: context.theme.appColors.primaryText,
                        ),
                        decoration: InputDecoration(
                          hintText: context.i18n.create_article_title_placeholder,
                          hintStyle: context.theme.appTextThemes.headline2.copyWith(
                            color: context.theme.appColors.tertiaryText,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (articleState.titleOverflowCount.value <= 0)
                      SizedBox(
                        height: 16.0.s,
                      )
                    else
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: ScreenSideOffset.defaultSmallMargin,
                          bottom: 4.0.s,
                        ),
                        child: _TextLimitIndicator(
                          value: articleState.titleOverflowCount.value,
                        ),
                      ),
                    ScreenSideOffset.small(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: articleState.editorFocusNotifier,
                        builder: (context, isFocused, child) {
                          return TextEditor(
                            articleState.textEditorController,
                            key: textEditorKey,
                            focusNode: textEditorFocusNode,
                            autoFocus: isFocused,
                            media: modifiedEvent != null ? articleState.media.value : null,
                            authorPubkey: currentPubkey,
                            placeholder: context.i18n.create_article_story_placeholder,
                            scrollController: scrollController,
                          );
                        },
                      ),
                    ),
                    if (articleState.descriptionOverflowCount.value > 0)
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: ScreenSideOffset.defaultSmallMargin,
                          top: 6.0.s,
                        ),
                        child: _TextLimitIndicator(
                          value: articleState.descriptionOverflowCount.value,
                        ),
                      ),
                    SizedBox(
                      height: 16.0.s,
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                ScreenSideOffset.small(
                  child: SuggestionsContainer(
                    scrollController: scrollController,
                    editorKey: textEditorKey,
                  ),
                ),
                const HorizontalSeparator(),
                ValueListenableBuilder<bool>(
                  valueListenable: articleState.isTitleFocused,
                  builder: (context, isTitleFocused, child) {
                    if (isTitleFocused) {
                      return const SizedBox.shrink();
                    }
                    return ScreenSideOffset.small(
                      child: ArticleFormToolbar(
                        textEditorController: articleState.textEditorController,
                        textEditorKey: textEditorKey,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextLimitIndicator extends StatelessWidget {
  const _TextLimitIndicator({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        '-$value',
        style: context.theme.appTextThemes.caption2.copyWith(
          color: context.theme.appColors.attentionRed,
        ),
      ),
    );
  }
}
