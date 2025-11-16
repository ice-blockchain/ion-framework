import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/info/info_modal.dart';
import 'package:ion/app/components/info/info_type.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/providers/boosted_posts_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/boost_post_modal/components/boost_info_row.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/utils/num.dart';

class ActivePostBoostContent extends HookConsumerWidget {
  const ActivePostBoostContent({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encodedEventRef = eventReference.encode();
    final boostDataAsync = ref.watch(boostedPostDataProvider(encodedEventRef));

    // Calculate remaining cost: totalBudget * durationLeft / duration
    final (balance, totalCost) = boostDataAsync.maybeWhen(
      data: (data) {
        if (data == null) return (0.0, 0.0);

        final totalBudget = data.cost;
        final duration = data.durationDays;
        final endDate = data.purchasedAt.add(Duration(days: duration));
        final now = DateTime.now();

        // Calculate remaining days
        final durationLeft = endDate.isAfter(now) ? endDate.difference(now).inDays : 0;

        // Calculate remaining cost
        return (duration > 0 ? (totalBudget * durationLeft / duration) : 0.0, totalBudget);
      },
      orElse: () => (0.0, 0.0),
    );

    // TODO: Get real totalViews from backend API
    const totalViews = 148632;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 16.0.s),
          Column(
            children: [
              Text(
                totalViews.toString(),
                style: context.theme.appTextThemes.headline1.copyWith(
                  color: context.theme.appColors.primaryAccent,
                ),
              ),
              SizedBox(height: 4.0.s),
              Text(
                context.i18n.boost_total_views,
                style: context.theme.appTextThemes.caption2.copyWith(
                  color: context.theme.appColors.secondaryText,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.0.s),
          Column(
            children: [
              BoostInfoRow(
                label: context.i18n.boost_balance_title,
                value: formatUSD(balance),
                onInfoTap: () => showSimpleBottomSheet<void>(
                  context: context,
                  child: const InfoModal(infoType: InfoType.boostBalance),
                ),
              ),
              SizedBox(height: 16.0.s),
              BoostInfoRow(
                label: context.i18n.boost_cost_title,
                value: boostDataAsync.maybeWhen(
                  data: (_) => formatUSD(totalCost),
                  loading: () => '...',
                  orElse: () => formatUSD(0),
                ),
                onInfoTap: () => showSimpleBottomSheet<void>(
                  context: context,
                  child: const InfoModal(infoType: InfoType.boostCost),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.0.s),
          Button(
            mainAxisSize: MainAxisSize.max,
            label: Text(context.i18n.boost_increase_boost),
            onPressed: () async {
              final encodedEventRef = eventReference.encode();

              await NewBoostPostModalRoute(eventReference: encodedEventRef).push<void>(context);
            },
          ),
          ScreenBottomOffset(),
        ],
      ),
    );
  }
}
