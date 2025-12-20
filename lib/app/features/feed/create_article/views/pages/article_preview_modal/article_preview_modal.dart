// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/create_article/providers/create_article_provider.r.dart';
import 'package:ion/app/features/feed/create_article/providers/draft_article_provider.m.dart';
import 'package:ion/app/features/feed/create_article/views/pages/article_preview_modal/components/article_preview.dart';
import 'package:ion/app/features/feed/create_article/views/pages/article_preview_modal/components/select_article_topics_item.dart';
import 'package:ion/app/features/feed/create_article/views/pages/article_preview_modal/components/select_article_who_can_reply_item.dart';
import 'package:ion/app/features/feed/hooks/use_preselect_topics.dart';
import 'package:ion/app/features/feed/providers/selected_interests_notifier.r.dart';
import 'package:ion/app/features/feed/providers/selected_who_can_reply_option_provider.r.dart';
import 'package:ion/app/features/feed/providers/topic_tooltip_visibility_notifier.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/nsfw/nsfw_submit_guard.dart';
import 'package:ion/app/features/user/providers/ugc_counter_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/services/ion_content_labeler/ion_content_labeler_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:showcaseview/showcaseview.dart';

class ArticlePreviewModal extends HookConsumerWidget {
  factory ArticlePreviewModal({
    Key? key,
  }) = ArticlePreviewModal.create;

  const ArticlePreviewModal._({super.key, this.modifiedEvent});

  factory ArticlePreviewModal.create({
    Key? key,
  }) {
    return ArticlePreviewModal._(
      key: key,
    );
  }

  factory ArticlePreviewModal.edit({
    required EventReference modifiedEvent,
    Key? key,
  }) {
    return ArticlePreviewModal._(
      key: key,
      modifiedEvent: modifiedEvent,
    );
  }

  final EventReference? modifiedEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DraftArticleState(
      :title,
      :image,
      :imageIds,
      :content,
      :imageColor,
      :imageUrl,
      :mediaAttachments,
    ) = ref.watch(draftArticleProvider);
    final whoCanReply = ref.watch(selectedWhoCanReplyOptionProvider);
    final selectedTopics = ref.watch(selectedInterestsNotifierProvider);
    final shownTooltip = useRef(false);
    final isProcessing = useState(false);
    final prefetchedUgcCounter = useState<int?>(null);

    usePreselectTopics(ref, eventReference: modifiedEvent);

    useEffect(
      () {
        unawaited(
          ref.read(ugcCounterProvider().future).then((value) {
            prefetchedUgcCounter.value = value;
            return value;
          }).catchError((_) => null),
        );
        return null;
      },
      const [],
    );

    return SheetContent(
      body: ShowCaseWidget(
        disableMovingAnimation: true,
        disableScaleAnimation: true,
        builder: (context) => Column(
          children: [
            NavigationAppBar.modal(
              title: Text(context.i18n.article_preview_title),
            ),
            const HorizontalSeparator(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 12.0.s),
                    const ArticlePreview(),
                    SizedBox(height: 12.0.s),
                    const HorizontalSeparator(),
                    SizedBox(height: 40.0.s),
                    const SelectArticleTopicsItem(),
                    SizedBox(height: 20.0.s),
                    const HorizontalSeparator(),
                    SizedBox(height: 20.0.s),
                    const SelectArticleWhoCanReplyItem(),
                    SizedBox(height: 40.0.s),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HorizontalSeparator(),
                SizedBox(height: 16.0.s),
                ScreenSideOffset.large(
                  child: Button(
                    trailingIcon: isProcessing.value ? const IONLoadingIndicator() : null,
                    leadingIcon: Assets.svg.iconFeedArticles.icon(
                      color: context.theme.appColors.onPrimaryAccent,
                    ),
                    onPressed: () async {
                      if (isProcessing.value) return;

                      if (!shownTooltip.value && selectedTopics.isEmpty) {
                        shownTooltip.value = true;
                        ref.read(topicTooltipVisibilityNotifierProvider.notifier).show();
                        return;
                      }

                      try {
                        isProcessing.value = true;

                        // NSFW validation before publishing (cover image and embedded images if available)
                        final imagesToCheck = <String>[
                          if (image?.path != null) image!.path,
                          ...mediaAttachments.values
                              .where((m) => m.mimeType.startsWith('image/'))
                              .map((m) => m.url),
                        ];
                        final isBlocked = await NsfwSubmitGuard.checkAndBlockImagePaths(
                          ref,
                          imagesToCheck,
                        );
                        if (isBlocked) return;

                        final labeler = await ref.read(ionContentLabelerProvider.future);
                        final detectedLanguage = await labeler.detectLanguageLabels(
                          Document.fromDelta(content).toPlainText(),
                        );

                        final type = modifiedEvent != null
                            ? CreateArticleOption.modify
                            : CreateArticleOption.plain;

                        if (modifiedEvent != null) {
                          unawaited(
                            ref.read(createArticleProvider(type).notifier).modify(
                                  title: title,
                                  content: content,
                                  topics: selectedTopics,
                                  coverImagePath: image?.path,
                                  whoCanReply: whoCanReply,
                                  imageColor: imageColor,
                                  originalImageUrl: imageUrl,
                                  eventReference: modifiedEvent!,
                                  language: detectedLanguage?.value,
                                  mediaAttachments: mediaAttachments,
                                ),
                          );
                        } else {
                          unawaited(
                            ref.read(createArticleProvider(type).notifier).create(
                                  title: title,
                                  content: content,
                                  topics: selectedTopics,
                                  coverImagePath: image?.path,
                                  mediaIds: imageIds,
                                  whoCanReply: whoCanReply,
                                  imageColor: imageColor,
                                  language: detectedLanguage?.value,
                                  ugcCounter: prefetchedUgcCounter.value,
                                ),
                          );
                        }

                        if (!ref.read(createArticleProvider(type)).hasError &&
                            ref.context.mounted) {
                          context.maybePop();

                          // We need also close ArticleFormModal after article is created or changed
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              context.maybePop();
                            }
                          });
                        }
                      } finally {
                        isProcessing.value = false;
                      }
                    },
                    label: Text(context.i18n.button_publish),
                    mainAxisSize: MainAxisSize.max,
                  ),
                ),
                ScreenBottomOffset(margin: 36.0.s),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
