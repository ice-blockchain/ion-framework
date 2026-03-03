// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/sharing_intent/shared_content.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';
import 'package:ion/generated/assets.gen.dart';

class ShareExternalContentOptions extends ConsumerWidget {
  const ShareExternalContentOptions({required this.content, super.key});

  final SharedContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      spacing: 10.0.s,
      children: [
        switch (content) {
          SharedText(:final text) => Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 48.0.s),
                child: Button(
                  type: ButtonType.secondary,
                  mainAxisSize: MainAxisSize.max,
                  leadingIcon: Assets.svg.iconCreatePost.icon(size: 24.0.s),
                  label: Text(context.i18n.create_post_external_content),
                  borderColor: context.theme.appColors.onTertiaryFill,
                  onPressed: () => _onPostShare(context, text),
                ),
              ),
            ),
        },
      ],
    );
  }

  void _onPostShare(BuildContext context, String text) {
    context.pop();
    final delta = _buildDelta(text);
    CreatePostRoute(content: delta).push<void>(context);
  }

  /// Converts shared text into Quill Delta JSON, auto-linking any URLs
  /// so they render as tappable links in the editor.
  String _buildDelta(String text) {
    const urlMatcher = UrlMatcher();
    final urlRegex = RegExp(urlMatcher.pattern);
    final ops = <Map<String, dynamic>>[];

    var lastEnd = 0;
    for (final match in urlRegex.allMatches(text)) {
      // Regex is intentionally loose; skip false positives (e.g. invalid TLDs)
      if (!urlMatcher.validate(match.group(0)!)) continue;

      if (match.start > lastEnd) {
        ops.add({'insert': text.substring(lastEnd, match.start)});
      }

      final url = match.group(0)!;
      ops.add({
        'insert': url,
        'attributes': {'link': url},
      });
      lastEnd = match.end;
    }

    // Quill requires every document to end with '\n'
    final remaining = lastEnd < text.length ? text.substring(lastEnd) : '';
    ops.add({'insert': '$remaining\n'});

    return jsonEncode(ops);
  }
}
