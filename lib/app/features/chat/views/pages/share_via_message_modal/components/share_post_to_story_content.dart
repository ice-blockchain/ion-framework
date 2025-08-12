// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/views/components/post/post.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

class SharePostToStoryContent extends StatelessWidget {
  const SharePostToStoryContent({
    required this.eventReference,
    required this.postItselfEntity,
    super.key,
  });

  final EventReference eventReference;
  final ModifiablePostEntity postItselfEntity;

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
              child: Post(
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
