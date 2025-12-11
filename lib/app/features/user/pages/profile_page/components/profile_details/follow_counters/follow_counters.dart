// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/dividers/gradient_vertical_divider.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/follow_type.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/follow_counters/follow_counters_cell.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/followers_count_provider.r.dart';

class FollowCounters extends ConsumerWidget {
  const FollowCounters({
    required this.pubkey,
    this.height = 36.0,
    this.profileMode = ProfileMode.light,
    this.padding,
    this.network = true,
    this.enableDecoration = true,
    super.key,
  });

  final String pubkey;
  final double height;
  final ProfileMode profileMode;
  final EdgeInsetsGeometry? padding;
  final bool network;
  final bool enableDecoration;

  Decoration _decoration(BuildContext context) {
    if (profileMode == ProfileMode.dark) {
      if (!enableDecoration) {
        return const BoxDecoration();
      }
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
    if (!enableDecoration) {
      return SizedBox(
        width: 16.s,
      );
    }
    if (profileMode == ProfileMode.dark) {
      return Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: 12.0.s),
        child: const GradientVerticalDivider(),
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
      return EdgeInsets.symmetric(horizontal: 16.0.s);
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
    final followListAsync = ref.watch(followListProvider(pubkey, network: network));
    final followersCountAsync = ref.watch(followersCountProvider(pubkey, network: network));
    final followingNumber = followListAsync.valueOrNull?.data.list.length;
    final followersNumber = followersCountAsync.valueOrNull;
    final bothAvailable = followingNumber != null && followersNumber != null;

    final isLoading = followListAsync.isLoading || followersCountAsync.isLoading;
    if (!isLoading && !bothAvailable && network) {
      return const SizedBox.shrink();
    }

    return Container(
      height: height.s,
      padding: padding ?? _padding,
      decoration: _decoration(context),
      child: Row(
        mainAxisSize: _mainAxisSize,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FollowCounterCellWrapper(
            isExpanded: profileMode != ProfileMode.dark,
            isLoading: isLoading,
            child: FollowCountersCell(
              pubkey: pubkey,
              usersNumber: followingNumber ?? 0,
              followType: FollowType.following,
              profileMode: profileMode,
            ),
          ),
          _divider(context),
          _FollowCounterCellWrapper(
            isExpanded: profileMode != ProfileMode.dark,
            isLoading: isLoading,
            child: FollowCountersCell(
              pubkey: pubkey,
              usersNumber: followersNumber ?? 0,
              followType: FollowType.followers,
              profileMode: profileMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowCounterCellWrapper extends StatelessWidget {
  const _FollowCounterCellWrapper({
    required this.child,
    required this.isExpanded,
    this.isLoading = false,
  });

  final Widget child;
  final bool isExpanded;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final content = isLoading ? const _FollowCounterLoadingCell() : child;

    if (!isExpanded) {
      return content;
    }
    return Expanded(
      child: content,
    );
  }
}

class _FollowCounterLoadingCell extends StatelessWidget {
  const _FollowCounterLoadingCell();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon placeholder
          Container(
            width: 16.0.s,
            height: 16.0.s,
            decoration: BoxDecoration(
              color: context.theme.appColors.secondaryBackground,
              borderRadius: BorderRadius.circular(2.0.s),
            ),
          ),
          SizedBox(width: 4.0.s),
          // Number placeholder
          Container(
            width: 24.0.s,
            height: 16.0.s,
            decoration: BoxDecoration(
              color: context.theme.appColors.secondaryBackground,
              borderRadius: BorderRadius.circular(4.0.s),
            ),
          ),
          SizedBox(width: 4.0.s),
          // Label placeholder
          Container(
            width: 40.0.s,
            height: 16.0.s,
            decoration: BoxDecoration(
              color: context.theme.appColors.secondaryBackground,
              borderRadius: BorderRadius.circular(4.0.s),
            ),
          ),
        ],
      ),
    );
  }
}
