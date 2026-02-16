// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/create_post/providers/onelink_resolved_quote_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/services/deep_link/appsflyer_deep_link_service.r.dart';
import 'package:ion/app/services/deep_link/shared_content_type.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/url.dart';

/// A hook that detects AppsFlyer OneLink URLs in the editor text,
/// resolves them to an [EventReference] for quotable content (posts, articles,
/// community tokens), removes the URL from the editor, and updates
/// [oneLinkResolvedQuoteNotifierProvider].
///
/// Only activates when [enabled] is true (should be false when the post
/// already has a static quotedEvent).
///
/// Returns the resolved [EventReference] or null.
EventReference? useOneLinkQuotedEvent({
  required WidgetRef ref,
  required QuillController textEditorController,
  required List<String> detectedUrls,
  required bool enabled,
}) {
  final resolvedRef = ref.watch(oneLinkResolvedQuoteNotifierProvider);
  final lastResolvedUrl = useRef<String?>(null);
  final isResolving = useRef(false);

  useEffect(
    () {
      if (!enabled) return null;

      final oneLinkUrl = detectedUrls.where(isOneLinkUrl).firstOrNull;

      // If there's no onelink URL, skip. Once a quote is resolved, it persists
      // even if the user deletes the link text. The provider is only reset
      // when the modal is reopened (via useOnInit in PostFormModal).
      if (oneLinkUrl == null) return null;

      // Skip if we already resolved this exact URL and the quote is still shown.
      // When the user cleared the quote (resolvedRef == null), re-resolve for any pasted URL.
      if (oneLinkUrl == lastResolvedUrl.value && resolvedRef != null) {
        _removeUrlFromEditor(textEditorController, oneLinkUrl);
        return null;
      }

      // Skip if already resolving
      if (isResolving.value) return null;

      isResolving.value = true;

      final service = ref.read(appsflyerDeepLinkServiceProvider);
      service.resolveOneLinkUrlAsync(oneLinkUrl).then((result) {
        isResolving.value = false;

        if (result == null || result.deepLinkValue == null || result.deepLinkValue!.isEmpty) {
          Logger.log('OneLink URL resolution returned no deep link value');
          return;
        }

        // Reject non-quotable content types (stories, profiles).
        // All other types (posts, articles, community tokens) are quotable.
        final contentType = result.contentType;
        if (contentType == SharedContentType.story || contentType == SharedContentType.profile) {
          return;
        }

        try {
          final eventReference = EventReference.fromEncoded(result.deepLinkValue!);

          lastResolvedUrl.value = oneLinkUrl;
          ref.read(oneLinkResolvedQuoteNotifierProvider.notifier).resolvedQuote = eventReference;

          // Remove the onelink URL from the editor text
          _removeUrlFromEditor(textEditorController, oneLinkUrl);
        } catch (error) {
          Logger.error('Failed to decode resolved deep link value: $error');
        }
      });

      return null;
    },
    [detectedUrls, enabled],
  );

  return resolvedRef;
}

/// Removes the first occurrence of [url] from the [QuillController] document.
void _removeUrlFromEditor(QuillController controller, String url) {
  final plainText = controller.document.toPlainText();
  final index = plainText.indexOf(url);
  if (index == -1) return;

  // Quill documents always end with a trailing '\n', so minimum length is 1.
  // Clamp cursor position to valid range after deletion.
  final maxOffset = max(0, controller.document.length - 1 - url.length);
  final safeOffset = min(index, maxOffset);

  controller.replaceText(
    index,
    url.length,
    '',
    TextSelection.collapsed(offset: safeOffset),
  );
}
