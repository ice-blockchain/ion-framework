// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/generated/assets.gen.dart';

enum AppUpdateType {
  updateRequired,
  upToDate,
  androidSoftUpdate,
  ;

  String get iconAsset {
    return switch (this) {
      AppUpdateType.updateRequired => Assets.svg.actionWalletUpdate,
      AppUpdateType.upToDate => Assets.svg.actionWalletChangelog,
      AppUpdateType.androidSoftUpdate => Assets.svg.actionWalletAppupdate,
    };
  }

  String get buttonIconAsset {
    return switch (this) {
      AppUpdateType.updateRequired => Assets.svg.iconFeedUpdate,
      AppUpdateType.upToDate => Assets.svg.iconFeedChangelog,
      AppUpdateType.androidSoftUpdate => Assets.svg.iconFeedUpdate,
    };
  }

  String getTitle(BuildContext context) => switch (this) {
        AppUpdateType.updateRequired => context.i18n.update_update_title,
        AppUpdateType.upToDate => context.i18n.update_uptodate_title,
        AppUpdateType.androidSoftUpdate => context.i18n.update_inapp_update_title,
      };

  String getDesc(BuildContext context) => switch (this) {
        AppUpdateType.updateRequired => context.i18n.update_update_desc,
        AppUpdateType.upToDate => context.i18n.update_uptodate_desc,
        AppUpdateType.androidSoftUpdate => context.i18n.update_inapp_update_desc,
      };

  String getActionTitle(BuildContext context) => switch (this) {
        AppUpdateType.updateRequired => context.i18n.update_update_action,
        AppUpdateType.upToDate => context.i18n.update_uptodate_action,
        AppUpdateType.androidSoftUpdate => context.i18n.update_uptodate_action,
      };
}
