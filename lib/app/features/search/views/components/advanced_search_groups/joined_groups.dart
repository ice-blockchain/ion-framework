// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/views/components/advanced_search_groups/advanced_search_group_list_item.dart';

class JoinedGroups extends StatelessWidget {
  const JoinedGroups({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      restorationId: 'search_joined_groups_scroll',
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
              avatarUrl: 'https://ice-staging.b-cdn.net/profile/default-profile-picture-16.png',
              displayName: 'HOT Crypto Updates',
              message: 'Interesting statistics on the mass distribution of cryptocurrencies.',
              joined: false,
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
