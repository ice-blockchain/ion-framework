// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/follow_type.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/follow_counters/follow_counters_cell.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/followers_count_provider.r.dart';

class FollowCounters extends ConsumerWidget {
  const FollowCounters({
    required this.pubkey,
    this.profileMode = ProfileMode.light,
    super.key,
  });

  final String pubkey;
  final ProfileMode profileMode;

  Decoration _decoration(BuildContext context) {
    if (profileMode == ProfileMode.dark) {
      return ShapeDecoration(
        color: context.theme.appColors.primaryBackground.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.53.s),
        ),
      );
    }
    return BoxDecoration(
      color: context.theme.appColors.tertiaryBackground,
      borderRadius: BorderRadius.circular(16.0.s),
    );
  }

  Widget _divider(BuildContext context) {
    if (profileMode == ProfileMode.dark) {
      return Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: 12.0.s),
        child: Opacity(
          opacity: 0.40,
          child: Container(
            height: 22.0.s,
            width: 0.44.s,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0x00ffffff),
                  Color(0xccffffff),
                  Color(0x00ffffff),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return VerticalDivider(
      width: 1.0.s,
      thickness: 0.5.s,
      indent: 8.0.s,
      endIndent: 8.0.s,
      color: context.theme.appColors.onTertiaryFill,
    );
  }

  EdgeInsets get _padding {
    if (profileMode == ProfileMode.dark) {
      return EdgeInsets.symmetric(horizontal: 13.0.s);
    }
    return EdgeInsets.zero;
  }

  MainAxisSize get _mainAxisSize {
    if (profileMode == ProfileMode.dark) {
      return MainAxisSize.min;
    }
    return MainAxisSize.max;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followListAsync = ref.watch(followListProvider(pubkey));
    final followersCountAsync = ref.watch(followersCountProvider(pubkey));
    final followingNumber = followListAsync.valueOrNull?.data.list.length;
    final followersNumber = followersCountAsync.valueOrNull;
    final bothAvailable = followingNumber != null && followersNumber != null;

    final isLoading = followListAsync.isLoading || followersCountAsync.isLoading;
    if (!isLoading && !bothAvailable) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 36.0.s,
      padding: _padding,
      decoration: _decoration(context),
      child: Row(
        mainAxisSize: _mainAxisSize,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (bothAvailable)
            _buildExpanded(
              child: FollowCountersCell(
                pubkey: pubkey,
                usersNumber: followingNumber,
                followType: FollowType.following,
                profileMode: profileMode,
              ),
              isExpanded: profileMode != ProfileMode.dark,
              isVisible: bothAvailable,
            ),
          _divider(context),
          _buildExpanded(
            child: FollowCountersCell(
              pubkey: pubkey,
              usersNumber: followersNumber ?? 0,
              followType: FollowType.followers,
              profileMode: profileMode,
            ),
            isExpanded: profileMode != ProfileMode.dark,
            isVisible: bothAvailable,
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded({
    required Widget child,
    required bool isExpanded,
    required bool isVisible,
  }) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }
    if (!isExpanded) {
      return child;
    }
    return Expanded(
      child: child,
    );
  }
}
