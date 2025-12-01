// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/text_input/ion_text_field.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class ChatTextField extends HookConsumerWidget {
  const ChatTextField({
    required this.onSubmitted,
    required this.textFieldController,
    required this.textFieldFocusNode,
    super.key,
  });

  final Future<void> Function({String? content, List<MediaFile>? mediaFiles}) onSubmitted;
  final TextEditingController textFieldController;
  final FocusNode textFieldFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onTextChanged = useCallback(
      (String text) {
        if (textFieldController.text.isEmpty) {
          textFieldFocusNode.requestFocus();
        } else {
          final text = textFieldController.text.trim();
          if (text.isNotEmpty) {
          } else {
            textFieldController.clear();
          }
        }
      },
      [textFieldController],
    );

    final onGifInsertedByAndroidKeyboard = useCallback(
      (KeyboardInsertedContent content) async {
        final mediaFile =
            await ref.read(mediaServiceProvider).convertKeyboardGifToMediaFile(content);
        if (mediaFile != null) {
          unawaited(onSubmitted(mediaFiles: [mediaFile]));
        }
      },
    );

    return IonTextField(
      focusNode: textFieldFocusNode,
      controller: textFieldController,
      maxLines: 5,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      onChanged: onTextChanged,
      onSubmitted: (_) => textFieldController.clear(),
      style: context.theme.appTextThemes.body2.copyWith(
        color: context.theme.appColors.primaryText,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          vertical: 7.0.s,
          horizontal: 12.0.s,
        ),
        fillColor: context.theme.appColors.onSecondaryBackground,
        filled: true,
        hintText: context.i18n.write_a_message,
        hintStyle: context.theme.appTextThemes.body2.copyWith(
          color: context.theme.appColors.quaternaryText,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.0.s),
          borderSide: BorderSide.none,
        ),
      ),
      contentInsertionConfiguration: ContentInsertionConfiguration(
        allowedMimeTypes: [LocalMimeType.gif.value],
        onContentInserted: onGifInsertedByAndroidKeyboard,
      ),
    );
  }
}
