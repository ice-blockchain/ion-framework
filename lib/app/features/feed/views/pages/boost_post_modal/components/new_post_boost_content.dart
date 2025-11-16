// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/info/info_modal.dart';
import 'package:ion/app/components/info/info_type.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/providers/boosted_posts_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/boost_post_modal/components/boost_info_row.dart';
import 'package:ion/app/features/feed/views/pages/boost_post_modal/components/boost_slider_row.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class NewPostBoostContent extends HookConsumerWidget {
  const NewPostBoostContent({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const minViews = 265602;
    const maxViews = 520525;
    const appleFeePercentage = 0.3;
    const taxes = 10.0;

    final dailyBudget = useState<double>(10); // 1, 5, 10, 25, 50
    final duration = useState<int>(7); // 1, 2, 3, 4, 5, 6, 7

    double getBudget() {
      return dailyBudget.value * duration.value;
    }

    double getAppleFee() {
      return getBudget() * appleFeePercentage;
    }

    double getTotalCost() {
      return getBudget() + getAppleFee() + taxes;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 16.0.s),
          Column(
            children: [
              Text(
                '$minViews - $maxViews',
                style: context.theme.appTextThemes.headline1.copyWith(
                  color: context.theme.appColors.primaryAccent,
                ),
              ),
              SizedBox(height: 4.0.s),
              Text(
                context.i18n.boost_approximately_views,
                style: context.theme.appTextThemes.caption2.copyWith(
                  color: context.theme.appColors.secondaryText,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.0.s),
          Column(
            children: [
              BoostSliderRow(
                label: context.i18n.boost_daily_budget_title,
                value: formatUSD(dailyBudget.value),
                predefinedValues: const [1.0, 5.0, 10.0, 25.0, 50.0],
                currentValue: dailyBudget.value,
                onChanged: (value) {
                  dailyBudget.value = value;
                },
                icon: Assets.svg.iconProfileTips,
              ),
              SizedBox(height: 16.0.s),
              BoostSliderRow(
                label: context.i18n.boost_duration_label,
                value: context.i18n.boost_duration_days(duration.value),
                min: 1,
                max: 7,
                currentValue: duration.value.toDouble(),
                onChanged: (value) {
                  duration.value = value.round();
                },
                icon: Assets.svg.iconFieldCalendar,
              ),
              SizedBox(height: 24.0.s),
              Column(
                children: [
                  BoostInfoRow(
                    label: context.i18n.boost_budget_title,
                    value: formatUSD(getBudget()),
                    onInfoTap: () => showSimpleBottomSheet<void>(
                      context: context,
                      child: const InfoModal(infoType: InfoType.boostBudget),
                    ),
                  ),
                  SizedBox(height: 12.0.s),
                  BoostInfoRow(
                    label: context.i18n.boost_apple_fee_title,
                    value: formatUSD(getAppleFee()),
                    onInfoTap: () => showSimpleBottomSheet<void>(
                      context: context,
                      child: const InfoModal(infoType: InfoType.boostAppleFee),
                    ),
                  ),
                  SizedBox(height: 12.0.s),
                  BoostInfoRow(
                    label: context.i18n.boost_taxes_title,
                    value: formatUSD(taxes),
                    onInfoTap: () => showSimpleBottomSheet<void>(
                      context: context,
                      child: const InfoModal(infoType: InfoType.boostTaxes),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24.0.s),
          Button(
            mainAxisSize: MainAxisSize.max,
            label: Text(
              context.i18n.boost_pay_amount(
                formatUSD(getTotalCost()),
              ),
            ),
            onPressed: () async {
              final encodedEventRef = eventReference.encode();
              final budget = getBudget();
              final durationDays = duration.value;
              await ref.read(boostedPostsProvider.notifier).addBoostedPost(
                    encodedEventRef,
                    budget,
                    durationDays,
                  );

              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          ScreenBottomOffset(),
        ],
      ),
    );
  }
}
