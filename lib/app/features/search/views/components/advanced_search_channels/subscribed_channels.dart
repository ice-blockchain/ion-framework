// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/views/components/advanced_search_groups/advanced_search_group_list_item.dart';

class SubscribedChannels extends StatelessWidget {
  const SubscribedChannels({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      restorationId: 'search_subscribed_channels_scroll',
      itemCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Column(
          children: [
            if (index == 0)
              SizedBox(
                height: 12.0.s,
              ),
            const AdvancedSearchGroupListItem(
              avatarUrl: 'https://ice-staging.b-cdn.net/profile/default-profile-picture-15.png',
              displayName: 'ICE Coin crypto',
              message: 'Exploring the intersection of finance and technology.',
              joined: false,
              isVerified: true,
              isION: true,
            ),
            HorizontalSeparator(
              height: 16.0.s,
            ),
          ],
        );
      },
    );
  }
}
