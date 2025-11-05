// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/components/tabs/tabs_header.dart';
import 'package:ion/app/features/feed/notifications/data/model/notifications_tab_type.dart';

class NotificationsHistoryTabsHeader extends ConsumerWidget {
  const NotificationsHistoryTabsHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const TabsHeader<NotificationsTabType>(
      tabTypes: NotificationsTabType.values,
    );
  }
}
