// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/segmented_control/segmented_control.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/providers/community_token_analytics_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/generated/assets.gen.dart';

enum CreatorTokensAnalyticsRange {
  day,
  week,
  month,
}

extension CreatorTokensAnalyticsRangeLabel on CreatorTokensAnalyticsRange {
  String get label {
    switch (this) {
      case CreatorTokensAnalyticsRange.day:
        return '24h';
      case CreatorTokensAnalyticsRange.week:
        return '7d';
      case CreatorTokensAnalyticsRange.month:
        return '30d';
    }
  }
}

extension CreatorTokensAnalyticsRangeDisplayLabel on CreatorTokensAnalyticsRange {
  String displayLabel(BuildContext context) {
    switch (this) {
      case CreatorTokensAnalyticsRange.day:
        return context.i18n.creator_tokens_analytics_range_day;
      case CreatorTokensAnalyticsRange.week:
        return context.i18n.creator_tokens_analytics_range_week;
      case CreatorTokensAnalyticsRange.month:
        return context.i18n.creator_tokens_analytics_range_month;
    }
  }
}

class CreatorTokensAnalyticsMetrics {
  const CreatorTokensAnalyticsMetrics({
    this.tokensLaunched,
    this.migrated,
    this.volume,
  });

  final String? tokensLaunched;
  final String? migrated;
  final String? volume;
}

class CreatorTokensAnalyticsSheet extends HookConsumerWidget {
  const CreatorTokensAnalyticsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = useState(CreatorTokensAnalyticsRange.day);
    final colors = context.theme.appColors;
    final textThemes = context.theme.appTextThemes;
    final metricsAsync = ref.watch(creatorTokensAnalyticsMetricsProvider);
    final metrics = metricsAsync.valueOrNull?[range.value];

    return SafeArea(
      child: Column(
        spacing: 10.0.s,
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            title: Text(context.i18n.creator_tokens_analytics_title),
            actions: const [NavigationCloseButton()],
          ),
          ScreenSideOffset.small(
            child: Column(
              children: [
                SegmentedControl(
                  labels: CreatorTokensAnalyticsRange.values
                      .map((r) => r.displayLabel(context))
                      .toList(),
                  selectedIndex: range.value.index,
                  onSelected: (i) => range.value = CreatorTokensAnalyticsRange.values[i],
                ),
                SizedBox(height: 12.0.s),
                metricsAsync.when(
                  data: (_) => _CreatorTokensAnalyticsMetricsContent(metrics: metrics),
                  loading: () => Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0.s),
                    child: Center(
                      child: SizedBox(
                        width: 24.0.s,
                        height: 24.0.s,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primaryAccent,
                        ),
                      ),
                    ),
                  ),
                  error: (_, __) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0.s),
                    child: Center(
                      child: Text(
                        context.i18n.creator_tokens_analytics_load_failed,
                        style: textThemes.caption.copyWith(color: colors.tertiaryText),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorTokensAnalyticsMetricsContent extends StatelessWidget {
  const _CreatorTokensAnalyticsMetricsContent({this.metrics});

  final CreatorTokensAnalyticsMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 9.0.s,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          spacing: 9.0.s,
          children: [
            Expanded(
              child: _AnalyticsStatCard(
                label: context.i18n.creator_tokens_analytics_tokens_launched,
                value: metrics?.tokensLaunched,
                trailingIcon: Assets.svg.iconTabsCoins,
              ),
            ),
            Expanded(
              child: _AnalyticsStatCard(
                label: context.i18n.creator_tokens_analytics_migrated,
                value: metrics?.migrated,
                trailingIcon: Assets.svg.iconTabsMigrated,
              ),
            ),
          ],
        ),
        _AnalyticsStatCard(
          label: context.i18n.creator_tokens_analytics_volume,
          value: metrics?.volume,
          trailingIcon: Assets.svg.iconMemeMarkers,
        ),
      ],
    );
  }
}

class _AnalyticsStatCard extends StatelessWidget {
  const _AnalyticsStatCard({
    required this.label,
    required this.value,
    required this.trailingIcon,
  });

  final String label;
  final String? value;
  final String trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textThemes = context.theme.appTextThemes;
    final displayValue = (value == null || value!.isEmpty) ? '-' : value!;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(12.0.s, 22.0.s, 12.0.s, 14.0.s),
      decoration: BoxDecoration(
        color: colors.primaryBackground,
        borderRadius: BorderRadius.circular(16.0.s),
      ),
      child: Column(
        spacing: 8.0.s,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textThemes.caption.copyWith(color: colors.onTertiaryBackground),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayValue,
                  style: textThemes.headline2.copyWith(color: colors.primaryText),
                ),
              ),
              trailingIcon.icon(
                size: 20.0.s,
                color: colors.onTertiaryBackground,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
