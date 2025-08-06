// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/quill_controller.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/views/pages/cancel_creation_modal/cancel_creation_modal.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';

class CreatePostAppBar extends HookWidget {
  const CreatePostAppBar({
    required this.createOption,
    required this.textEditorController,
    super.key,
  });

  final CreatePostOption createOption;
  final QuillController textEditorController;

  Future<void> _handleClose({
    required BuildContext context,
    required FocusNode focusNode,
    required bool finishedEditing,
  }) async {
    if (textEditorController.document.isEmpty()) {
      context.pop(finishedEditing);
      return;
    }

    await showSimpleBottomSheet<void>(
      context: context,
      child: CancelCreationModal(
        title: context.i18n.cancel_creation_post_title,
        onCancel: () => {
          focusNode.unfocus(),
          textEditorController.clearContent(
            ignoreFocus: false,
          ),
          Navigator.of(context).pop(finishedEditing),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final isVideo = createOption == CreatePostOption.video;

    return NavigationAppBar.modal(
      showBackButton: isVideo,
      title: Text(createOption.getTitle(context)),
      onBackPress: () => _handleClose(
        context: context,
        focusNode: focusNode,
        finishedEditing: false,
      ),
      actions: [
        NavigationCloseButton(
          onPressed: () => _handleClose(
            context: context,
            focusNode: focusNode,
            finishedEditing: true,
          ),
        ),
      ],
    );
  }
}
