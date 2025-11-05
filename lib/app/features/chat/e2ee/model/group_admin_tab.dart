// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/features/components/tabs/tab_type.dart';
import 'package:ion/generated/assets.gen.dart';

enum GroupAdminTab implements TabType {
  members,
  media,
  links;

  @override
  String get iconAsset {
    return switch (this) {
      GroupAdminTab.members => Assets.svg.iconSearchFollowers,
      GroupAdminTab.media => Assets.svg.iconGalleryOpen,
      GroupAdminTab.links => Assets.svg.iconArticleLink,
    };
  }

  @override
  String getTitle(BuildContext context) {
    switch (this) {
      case GroupAdminTab.members:
        return context.i18n.group_admin_tab_members;
      case GroupAdminTab.media:
        return context.i18n.common_media;
      case GroupAdminTab.links:
        return context.i18n.common_links;
    }
  }
}
