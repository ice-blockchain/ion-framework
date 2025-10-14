// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

enum FollowType {
  followers,
  following,
  relevant;

  String get iconAsset {
    return switch (this) {
      FollowType.followers || FollowType.relevant => Assets.svg.iconSearchFollow,
      FollowType.following => Assets.svg.iconSearchFollowers,
    };
  }

  String getTitle(BuildContext context) {
    switch (this) {
      case FollowType.followers || FollowType.relevant:
        return context.i18n.profile_followers;
      case FollowType.following:
        return context.i18n.profile_following;
    }
  }

  String getTitleWithCounter(BuildContext context, int counter) {
    final count = formatCount(counter);

    switch (this) {
      case FollowType.followers || FollowType.relevant:
        return context.i18n.profile_followers_with_counter(count);
      case FollowType.following:
        return context.i18n.profile_following_with_counter(count);
    }
  }
}
