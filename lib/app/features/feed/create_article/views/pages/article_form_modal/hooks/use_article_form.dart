// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/hooks/use_quill_controller.dart';
import 'package:ion/app/components/text_editor/utils/delta_bridge.dart';
import 'package:ion/app/features/feed/create_article/providers/draft_article_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/providers/mentions/article_mentions_restored_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/providers/image_proccessor_notifier.m.dart';
import 'package:ion/app/services/markdown/quill.dart';
import 'package:ion/app/services/media_service/image_proccessing_config.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class ArticleFormState {
  ArticleFormState({
    required this.selectedImage,
    required this.selectedImageUrl,
    required this.titleFilled,
    required this.titleController,
    required this.textEditorController,
    required this.isButtonEnabled,
    required this.editorFocusNotifier,
    required this.onNext,
    required this.titleFocusNode,
    required this.isTitleFocused,
    required this.media,
    required this.titleOverflowCount,
    required this.isTitleLengthValid,
    required this.descriptionOverflowCount,
    required this.isDescriptionLengthValid,
  });

  final ValueNotifier<MediaFile?> selectedImage;
  final ValueNotifier<String?> selectedImageUrl;
  final ValueNotifier<bool> titleFilled;
  final TextEditingController titleController;
  final QuillController textEditorController;
  final bool isButtonEnabled;
  final ValueNotifier<bool> editorFocusNotifier;
  final void Function() onNext;
  final FocusNode titleFocusNode;
  final ValueNotifier<bool> isTitleFocused;
  final ValueNotifier<Map<String, MediaAttachment>?> media;
  final ValueNotifier<int> titleOverflowCount;
  final ValueNotifier<bool> isTitleLengthValid;
  final ValueNotifier<int> descriptionOverflowCount;
  final ValueNotifier<bool> isDescriptionLengthValid;
}

ArticleFormState useArticleForm(WidgetRef ref, {EventReference? modifiedEvent}) {
  final selectedImage = useState<MediaFile?>(null);
  final media = useState<Map<String, MediaAttachment>?>(null);
  final selectedImageUrl = useState<String?>(null);
  final selectedImageUrlColor = useState<String?>(null);
  final titleFilled = useState(false);
  final textEditorController = useQuillController();
  final editorFocusNotifier = useState<bool>(false);
  final titleController = useTextEditingController();
  final titleFocusNode = useFocusNode();
  final isTitleFocused = useState(false);
  final isTextValid = useState(false);
  final titleOverflowCount = useState<int>(0);
  final isTitleLengthValid = useState(true);
  final descriptionOverflowCount = useState<int>(0);
  final isDescriptionLengthValid = useState(true);
  const titleMaxLength = 120;
  const descriptionMaxLength = 25001;

  useEffect(
    () {
      void onFocusChange() {
        isTitleFocused.value = titleFocusNode.hasFocus;
      }

      titleFocusNode.addListener(onFocusChange);
      return () => titleFocusNode.removeListener(onFocusChange);
    },
    [titleFocusNode],
  );

  final processorState =
      ref.watch(imageProcessorNotifierProvider(ImageProcessingType.articleCover));

  useEffect(
    () {
      processorState.whenOrNull(
        processed: (file) {
          selectedImage.value = file;
        },
      );
      return;
    },
    [processorState],
  );

  useEffect(
    () {
      if (modifiedEvent != null) {
        final modifiableEntity =
            ref.read(ionConnectEntityProvider(eventReference: modifiedEvent)).valueOrNull;

        if (modifiableEntity is ArticleEntity) {
          if (modifiableEntity.data.title != null) {
            titleController.text = modifiableEntity.data.title!;
            titleFilled.value = true;

            final currentLength = titleController.text.length;
            if (currentLength > titleMaxLength) {
              titleOverflowCount.value = currentLength - titleMaxLength;
              isTitleLengthValid.value = false;
            }
          }

          final parsedDelta = parseAndConvertDelta(
            modifiableEntity.data.richText?.content,
            modifiableEntity.data.content,
          );

          // Restore mentions and convert to embeds
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final restoredDelta = await ref.read(
              articleMentionsRestoredProvider(
                delta: parsedDelta,
                relatedPubkeys: modifiableEntity.data.relatedPubkeys,
                mentionMarketCapLabel: modifiableEntity.data.mentionMarketCapLabel,
              ).future,
            );

            // Convert attributes to embeds for editor
            final deltaWithEmbeds = DeltaBridge.normalizeToEmbedFormat(restoredDelta);
            textEditorController.document = Document.fromDelta(deltaWithEmbeds);
          });

          if (modifiableEntity.data.image != null) {
            selectedImageUrl.value = modifiableEntity.data.image;
            selectedImageUrlColor.value = modifiableEntity.data.colorLabel?.values.firstOrNull;
          }

          media.value = modifiableEntity.data.media;
        }
      }
      return null;
    },
    [modifiedEvent],
  );

  useEffect(
    () {
      void listener() {
        final currentLength = titleController.text.length;

        if (currentLength > titleMaxLength) {
          titleOverflowCount.value = currentLength - titleMaxLength;
          isTitleLengthValid.value = false;
        } else {
          titleOverflowCount.value = 0;
          isTitleLengthValid.value = true;
        }

        titleFilled.value = titleController.text.trim().isNotEmpty;
      }

      titleController.addListener(listener);
      return () => titleController.removeListener(listener);
    },
    [titleController],
  );

  useEffect(
    () {
      void listener() {
        final descriptionText = textEditorController.document.toPlainText();
        isTextValid.value = descriptionText.trim().isNotEmpty;

        final isLengthValid = descriptionText.length <= descriptionMaxLength;
        descriptionOverflowCount.value =
            isLengthValid ? 0 : descriptionText.length - descriptionMaxLength;
        isDescriptionLengthValid.value = isLengthValid;
      }

      textEditorController.addListener(listener);
      return () => textEditorController.removeListener(listener);
    },
    [textEditorController],
  );

  void onNext() {
    ref.read(draftArticleProvider.notifier).updateArticleDetails(
          textEditorController,
          selectedImage.value,
          titleController.text,
          selectedImageUrl.value,
          selectedImageUrlColor.value,
          media.value,
        );
  }

  final isButtonEnabled = useMemoized(
    () {
      return (selectedImage.value != null || selectedImageUrl.value != null) &&
          titleFilled.value &&
          isTextValid.value &&
          isTitleLengthValid.value &&
          isDescriptionLengthValid.value;
    },
    [
      selectedImage.value,
      selectedImageUrl.value,
      titleFilled.value,
      isTextValid.value,
      isTitleLengthValid.value,
      isDescriptionLengthValid.value,
    ],
  );

  return ArticleFormState(
    selectedImage: selectedImage,
    selectedImageUrl: selectedImageUrl,
    titleFilled: titleFilled,
    titleController: titleController,
    textEditorController: textEditorController,
    isButtonEnabled: isButtonEnabled,
    editorFocusNotifier: editorFocusNotifier,
    onNext: onNext,
    titleFocusNode: titleFocusNode,
    isTitleFocused: isTitleFocused,
    media: media,
    titleOverflowCount: titleOverflowCount,
    isTitleLengthValid: isTitleLengthValid,
    descriptionOverflowCount: descriptionOverflowCount,
    isDescriptionLengthValid: isDescriptionLengthValid,
  );
}
