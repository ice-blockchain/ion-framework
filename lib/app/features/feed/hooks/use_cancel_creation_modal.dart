// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/features/feed/views/pages/cancel_creation_modal/cancel_creation_modal.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';

Future<void> Function() useCancelCreationModal({
  required String title,
  required QuillController? textEditorController,
}) {
  final context = useContext();
  final isModalShown = useState(false);
  final wasEdited = useRef(false);

  useEffect(
    () {
      if (textEditorController == null) return null;

      textEditorController.document.changes.first.then((_) {
        if (context.mounted) {
          wasEdited.value = true;
        }
      });

      return null;
    },
    [textEditorController],
  );

  final cancelCreationModal = useCallback(
    () async {
      final hasMeaningfulContent =
          textEditorController?.document.toPlainText().trim().isNotEmpty ?? false;

      if (!wasEdited.value || !hasMeaningfulContent) {
        if (context.mounted) context.pop();
        return;
      }

      if (isModalShown.value || !context.mounted) return;

      try {
        isModalShown.value = true;
        await showSimpleBottomSheet<void>(
          context: context,
          child: CancelCreationModal(
            title: title,
            onCancel: () {
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        );
      } finally {
        if (context.mounted) {
          isModalShown.value = false;
        }
      }
    },
    [textEditorController],
  );

  return cancelCreationModal;
}
