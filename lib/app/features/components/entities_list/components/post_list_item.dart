// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/post/post.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/typedefs/typedefs.dart';

class PostListItem extends StatelessWidget {
  const PostListItem({
    required this.eventReference,
    this.displayParent = false,
    this.showNotInterested = true,
    this.onVideoTap,
    super.key,
  });

  final EventReference eventReference;

  final bool displayParent;

  final OnVideoTapCallback? onVideoTap;

  final bool showNotInterested;

  @override
  Widget build(BuildContext context) {
    // TODO: process 20002 in the feed provider to fetch 10002

    return GestureDetector(
      onTap: () => PostDetailsRoute(eventReference: eventReference.encode()).push<void>(context),
      behavior: HitTestBehavior.opaque,
      child: Post(
        showNotInterested: showNotInterested,
        eventReference: eventReference,
        displayParent: displayParent,
        onVideoTap: onVideoTap,
        headerOffset: 12.0.s,
        network: false,
        plainInlineStyles: true,
      ),
    );
  }
}
