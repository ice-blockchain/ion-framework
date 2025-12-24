// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:ion/app/extensions/extensions.dart';

/// Hook that ensures an input field is visible when keyboard appears
///
/// Scrolls the input field into view when the keyboard appears and the input is focused.
/// Uses intelligent scrolling that only scrolls if the input would be hidden by the keyboard.
///
/// [inputKey] - GlobalKey for the input field widget
/// [isInputFocused] - State indicating if the input is currently focused
/// [context] - BuildContext to access scrollable ancestor and media query
void useEnsureInputVisibility({
  required GlobalKey inputKey,
  required ValueNotifier<bool> isInputFocused,
  required BuildContext context,
}) {
  // Scroll threshold: pixels from bottom of visible area before triggering scroll
  final scrollThreshold = 100.0.s;
  // Extra padding above keyboard when scrolling input into view
  final scrollPadding = 150.0.s;

  useEffect(
    () {
      final keyboardVisibilityController = KeyboardVisibilityController();
      final subscription = keyboardVisibilityController.onChange.listen((isVisible) {
        if (isVisible && isInputFocused.value) {
          // Capture context-dependent values before async gap
          if (!context.mounted) return;
          final scrollable = Scrollable.maybeOf(context);
          final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

          // Wait for keyboard animation to complete, then scroll
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!context.mounted) return;

            final inputContext = inputKey.currentContext;
            if (inputContext != null) {
              final renderBox = inputContext.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                if (scrollable != null && scrollable.position.hasContentDimensions) {
                  final position = renderBox.localToGlobal(Offset.zero);
                  if (!scrollable.context.mounted) {
                    return;
                  }
                  // ignore: use_build_context_synchronously
                  final viewport = scrollable.context.findRenderObject() as RenderBox?;
                  if (viewport != null) {
                    final viewportHeight = viewport.size.height;
                    final availableHeight = viewportHeight - keyboardHeight;

                    // Calculate if input is below visible area
                    if (position.dy > availableHeight - scrollThreshold) {
                      // Scroll to bring input into view, keeping it near bottom
                      final targetOffset = scrollable.position.pixels +
                          (position.dy - availableHeight + scrollPadding);
                      scrollable.position.animateTo(
                        targetOffset.clamp(0.0, scrollable.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  }
                } else {
                  // Fallback to ensureVisible if scrollable not found
                  Scrollable.ensureVisible(
                    inputContext,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
                  );
                }
              }
            }
          });
        }
      });
      return subscription.cancel;
    },
    [isInputFocused.value],
  );
}
