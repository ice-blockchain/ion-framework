// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/community_token_live.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class CommunityTokenLiveListItem extends StatelessWidget {
  const CommunityTokenLiveListItem({
    required this.eventReference,
    this.network = false,
    super.key,
  });

  final EventReference eventReference;

  final bool network;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => PostDetailsRoute(eventReference: eventReference.encode()).push<void>(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: 12.0.s),
        child: CommunityTokenLive(
          eventReference: eventReference,
          network: network,
        ),
      ),
    );
  }
}
