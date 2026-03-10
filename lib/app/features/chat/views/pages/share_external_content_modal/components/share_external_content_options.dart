// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/sharing_intent/shared_content.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:mime/mime.dart';

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
                  onPressed: () => _onTextPostShare(context, text),
                ),
              ),
            ),
          SharedImage(:final paths) => Expanded(
              child: Row(
                children: [
                  const _Spacer(),
                  Expanded(
                    child: Button(
                      type: ButtonType.secondary,
                      mainAxisSize: MainAxisSize.max,
                      leadingIcon: Assets.svg.iconCreatePost.icon(size: 24.0.s),
                      label: Text(context.i18n.create_post_external_content),
                      borderColor: context.theme.appColors.onTertiaryFill,
                      onPressed: () => _onImagePostShare(context, paths),
                    ),
                  ),
                  const _Spacer(),
                  Expanded(
                    child: Button(
                      type: ButtonType.secondary,
                      mainAxisSize: MainAxisSize.max,
                      leadingIcon: Assets.svg.iconFeedStory
                          .icon(size: 24.0.s, color: context.theme.appColors.primaryAccent),
                      label: Text(context.i18n.feed_add_story),
                      borderColor: context.theme.appColors.onTertiaryFill,
                      onPressed: () => _onImageStoryShare(context, paths.first),
                    ),
                  ),
                  const _Spacer(),
                ],
              ),
            ),
        },
      ],
    );
  }

  void _onTextPostShare(BuildContext context, String text) {
    context.pop();
    CreatePostRoute(content: _buildDelta(text)).push<void>(context);
  }

  Future<void> _onImagePostShare(BuildContext context, List<String> paths) async {
    context.pop();
    final enriched = await Future.wait(paths.map(mediaFileFromPath));
    final attachedMedia = jsonEncode(enriched.map((f) => f.toJson()).toList());
    if (context.mounted) {
      await CreatePostRoute(attachedMedia: attachedMedia).push<void>(context);
    }
  }

  void _onImageStoryShare(BuildContext context, String path) {
    context.pop();
    StoryPreviewRoute(path: path, mimeType: lookupMimeType(path)).push<void>(context);
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

class _Spacer extends StatelessWidget {
  const _Spacer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 10.s);
  }
}
