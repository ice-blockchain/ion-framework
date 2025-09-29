// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/utils/quill_style_manager.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/actions_toolbar_button/actions_toolbar_button.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';
import 'package:ion/app/utils/text_input_formatters.dart';
import 'package:ion/generated/assets.gen.dart';

class ToolbarLinkButton extends HookWidget {
  const ToolbarLinkButton({
    required this.textEditorController,
    super.key,
  });

  final QuillController textEditorController;

  @override
  Widget build(BuildContext context) {
    final styleManager =
        useMemoized(() => QuillStyleManager(textEditorController), [textEditorController]);

    final selectionState = useState<TextSelection>(textEditorController.selection);
    useEffect(
      () {
        void handleSelectionChange() {
          selectionState.value = textEditorController.selection;
        }

        textEditorController.addListener(handleSelectionChange);
        return () => textEditorController.removeListener(handleSelectionChange);
      },
      [textEditorController],
    );
    final selection = selectionState.value;

    final hasNonWhitespaceSelection = textEditorController.document
        .toPlainText()
        .substring(selection.start, selection.end)
        .trim()
        .isNotEmpty;

    return ActionsToolbarButton(
      icon: Assets.svg.iconArticleLink,
      enabled: hasNonWhitespaceSelection,
      onPressed: () async {
        final localContext = context;
        String? existingLink;
        final linkAttribute =
            textEditorController.getSelectionStyle().attributes[Attribute.link.key];
        if (linkAttribute != null) {
          existingLink = linkAttribute.value as String?;
        }

        final resultLink = await _showCupertinoLinkDialog(
          context: localContext,
          initialValue: existingLink,
        );

        if (!localContext.mounted) return;

        if (resultLink != null) {
          final url = resultLink.trim();
          if (RegExp(const UrlMatcher().pattern).hasMatch(url)) {
            styleManager.toggleLinkStyle(url);
          }
        }
      },
    );
  }

  Future<String?> _showCupertinoLinkDialog({
    required BuildContext context,
    String? initialValue,
  }) {
    final linkController = TextEditingController(text: initialValue ?? '');
    final linkFocusNode = FocusNode();

    return showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          linkFocusNode.requestFocus();
        });
        return CupertinoAlertDialog(
          title: Text(dialogContext.i18n.toolbar_link_title),
          content: SizedBox(
            height: 44,
            child: Column(
              children: [
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: linkController,
                  focusNode: linkFocusNode,
                  placeholder: dialogContext.i18n.toolbar_link_placeholder,
                  placeholderStyle: dialogContext.theme.appTextThemes.body2.copyWith(
                    color: dialogContext.theme.appColors.tertiaryText,
                  ),
                  style: dialogContext.theme.appTextThemes.body2.copyWith(
                    color: dialogContext.theme.appColors.primaryText,
                  ),
                  inputFormatters: [
                    emojiRestrictionFormatter(),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                dialogContext.i18n.button_cancel,
                style: TextStyle(color: dialogContext.theme.appColors.primaryAccent),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            CupertinoDialogAction(
              child: Text(
                dialogContext.i18n.button_link,
                style: TextStyle(color: dialogContext.theme.appColors.primaryAccent),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(linkController.text.trim());
              },
            ),
          ],
        );
      },
    );
  }
}
