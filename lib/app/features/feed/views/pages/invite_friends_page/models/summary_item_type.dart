// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

enum SummaryItemType {
  totalReferrals,
  upgrades,
  deFi,
  ads;

  String toText(BuildContext context) => switch (this) {
        SummaryItemType.totalReferrals => context.i18n.invite_friends_summary_referrals_text,
        SummaryItemType.upgrades => context.i18n.invite_friends_summary_upgrades_text,
        SummaryItemType.deFi => context.i18n.invite_friends_summary_defi_text,
        SummaryItemType.ads => context.i18n.invite_friends_summary_ads_text,
      };
}
