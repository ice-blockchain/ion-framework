// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/e2ee/model/group_admin_tab.dart';
import 'package:ion/app/features/components/tabs/tabs_header.dart';

class GroupTabsHeader extends ConsumerWidget {
  const GroupTabsHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const TabsHeader<GroupAdminTab>(
      tabTypes: GroupAdminTab.values,
    );
  }
}
