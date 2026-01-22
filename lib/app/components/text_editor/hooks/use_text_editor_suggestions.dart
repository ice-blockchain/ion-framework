// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/text_editor.dart';
import 'package:ion/app/features/feed/providers/suggestions/suggestions_notifier_provider.r.dart';

class TextEditorSuggestionsState {
  const TextEditorSuggestionsState({
    required this.isVisible,
    required this.suggestions,
    required this.taggingCharacter,
    required this.isLoading,
  });

  final bool isVisible;
  final List<Object> suggestions;
  final String taggingCharacter;
  final bool isLoading;
}

TextEditorSuggestionsState useTextEditorSuggestions({
  required ScrollController scrollController,
  required GlobalKey<TextEditorState> editorKey,
  required WidgetRef ref,
}) {
  final suggestionsState = ref.watch(suggestionsNotifierProvider);
  final isScrolling = useRef(false);

  final quillController = editorKey.currentState?.quillController;

  useEffect(
    () {
      void onTextChange() {
        // Only auto-scroll when suggestions are visible to avoid interfering with normal editing
        if (isScrolling.value || !suggestionsState.isVisible) return;

        final editorContext = editorKey.currentContext;
        if (editorContext != null && scrollController.hasClients) {
          isScrolling.value = true;

          Scrollable.ensureVisible(
            editorContext,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          ).then((_) {
            isScrolling.value = false;
          });
        }
      }

      quillController?.addListener(onTextChange);
      return () => quillController?.removeListener(onTextChange);
    },
    [quillController, suggestionsState.isVisible],
  );

  useEffect(
    () {
      if (suggestionsState.isVisible && !isScrolling.value) {
        if (scrollController.hasClients) {
          isScrolling.value = true;

          scrollController
              .animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
              .then((_) {
            isScrolling.value = false;
          });
        }
      }
      return null;
    },
    [suggestionsState.isVisible],
  );

  return TextEditorSuggestionsState(
    isVisible: suggestionsState.isVisible,
    suggestions: suggestionsState.suggestions,
    taggingCharacter: suggestionsState.taggingCharacter,
    isLoading: suggestionsState.isLoading,
  );
}
