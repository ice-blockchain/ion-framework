// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/text_input/ion_text_field.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/create_article/providers/draft_article_provider.m.dart';

class CodeBlockContent extends HookConsumerWidget {
  const CodeBlockContent({
    required this.onRemoveBlock,
    required this.content,
    this.codeBlockId,
    this.readOnly = false,
    super.key,
  });

  final VoidCallback onRemoveBlock;
  final String content;
  final String? codeBlockId;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeText = useState(content);
    final textController = useTextEditingController(text: content);
    final focusNode = useFocusNode();

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 12.0.s, top: 0.0.s, start: 12.0.s, end: 12.0.s),
      child: KeyboardListener(
        focusNode: focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              codeText.value.trim().isEmpty) {
            if (!readOnly && codeBlockId != null) {
              ref.read(draftArticleProvider.notifier).removeCodeBlock(codeBlockId!);
            }
            onRemoveBlock();
          }
        },
        child: IonTextField(
          controller: textController,
          readOnly: readOnly,
          onChanged: (value) {
            codeText.value = value;
            if (!readOnly && codeBlockId != null) {
              ref.read(draftArticleProvider.notifier).updateCodeBlock(codeBlockId!, value);
            }
          },
          maxLines: null,
          cursorColor: context.theme.appColors.primaryAccent,
          cursorHeight: 22.0.s,
          style: TextStyle(
            fontFamily: 'Monaco',
            fontSize: 12.0.s,
            color: context.theme.appColors.primaryText,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
