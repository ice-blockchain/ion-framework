// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/feed/views/components/article/article.dart';
import 'package:ion/app/features/feed/views/components/post/post.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

class SharePostToStoryContent extends StatelessWidget {
  const SharePostToStoryContent({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16.0.s),
          child: Material(
            color: context.theme.appColors.secondaryBackground,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0.s),
              child: eventReference.isArticleReference
                  ? Article(
                      eventReference: eventReference,
                      footer: const SizedBox.shrink(),
                      showActionButtons: false,
                    )
                  : Post(
                      eventReference: eventReference,
                      footer: const SizedBox.shrink(),
                      topOffset: 0,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
