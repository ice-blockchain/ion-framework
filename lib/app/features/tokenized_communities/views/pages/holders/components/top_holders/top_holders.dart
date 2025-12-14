// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/holder_tile.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/top_holders/components/top_holders_empty.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/components/top_holders/components/top_holders_skeleton.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/providers/token_bonding_curve_progress_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/holders/providers/token_top_holders_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:visibility_detector/visibility_detector.dart';

const int holdersCountLimit = 5;

class TopHolders extends StatelessWidget {
  const TopHolders({
    required this.externalAddress,
    required this.token,
    this.onTitleVisibilityChanged,
    super.key,
  });

  final String externalAddress;
  final CommunityToken token;
  final ValueChanged<double>? onTitleVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return ColoredBox(
      color: colors.secondaryBackground,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              externalAddress: externalAddress,
              onTitleVisibilityChanged: onTitleVisibilityChanged,
            ),
            SizedBox(height: 14.0.s),
            _TopHolderList(token: token, externalAddress: externalAddress),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.externalAddress,
    this.onTitleVisibilityChanged,
  });

  final String externalAddress;
  final ValueChanged<double>? onTitleVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final titleContent = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _HeaderTitle(externalAddress: externalAddress),
        const Spacer(),
        _HeaderViewAllButton(externalAddress: externalAddress),
      ],
    );
    if (onTitleVisibilityChanged != null) {
      return VisibilityDetector(
        key: UniqueKey(),
        onVisibilityChanged: (info) {
          onTitleVisibilityChanged?.call(info.visibleFraction);
        },
        child: titleContent,
      );
    }

    return titleContent;
  }
}

class _HeaderTitle extends ConsumerWidget {
  const _HeaderTitle({
    required this.externalAddress,
  });

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    return Row(
      children: [
        Assets.svg.iconSearchGroups.icon(size: 18.0.s),
        SizedBox(width: 6.0.s),
        Text(
          i18n.top_holders_title,
          style: texts.subtitle3.copyWith(color: colors.onTertiaryBackground),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _HeaderViewAllButton extends ConsumerWidget {
  const _HeaderViewAllButton({
    required this.externalAddress,
  });

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    final holdersCount = ref
            .watch(tokenTopHoldersProvider(externalAddress, limit: holdersCountLimit))
            .valueOrNull
            ?.length ??
        0;

    if (holdersCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        HoldersRoute(externalAddress: externalAddress).push<void>(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 4.0.s),
        child: Text(
          i18n.core_view_all,
          style: texts.caption2.copyWith(color: colors.primaryAccent),
        ),
      ),
    );
  }
}

class _TopHolderList extends ConsumerWidget {
  const _TopHolderList({
    required this.externalAddress,
    required this.token,
  });

  final CommunityToken token;
  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bondingCurveProgress =
        ref.watch(tokenBondingCurveProgressProvider(externalAddress)).valueOrNull;

    final holdersAsync =
        ref.watch(tokenTopHoldersProvider(externalAddress, limit: holdersCountLimit));
    return holdersAsync.when(
      data: (holders) {
        final hasBondingCurve = bondingCurveProgress != null;

        if (holders.isEmpty && !hasBondingCurve) {
          return const TopHoldersEmpty();
        }

        final extra = hasBondingCurve ? 1 : 0;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: holders.length + extra,
          itemBuilder: (context, index) {
            if (hasBondingCurve && index == 0) {
              return BondingCurveHolderTile(
                bondingCurveProgress: bondingCurveProgress,
                token: token,
              );
            }

            final holderIndex = index - extra;
            final holder = holders[holderIndex];
            return TopHolderTile(holder: holder);
          },
          separatorBuilder: (context, index) => SizedBox(height: 4.0.s),
        );
      },
      error: (error, stackTrace) => const TopHoldersEmpty(),
      loading: () => TopHoldersSkeleton(count: holdersCountLimit, seperatorHeight: 4.0.s),
    );
  }
}
