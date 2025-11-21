// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/info/info_modal.dart';
import 'package:ion/app/components/info/info_type.dart';
import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:ion/app/components/message_notification/providers/message_notification_notifier_provider.r.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/providers/boosted_posts_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/boost_post_modal/components/boost_info_row.dart';
import 'package:ion/app/features/feed/views/pages/boost_post_modal/components/boost_slider_row.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/iap/boost_post_products.dart';
import 'package:ion/app/services/logger/logger.dart';
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

    final dailyBudget = useState<double>(BoostPostProducts.defaultBudget);
    final duration = useState<int>(BoostPostProducts.defaultDuration);

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
                predefinedValues: BoostPostProducts.budgetValues,
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
                min: BoostPostProducts.minDuration.toDouble(),
                max: BoostPostProducts.maxDuration.toDouble(),
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
          _DebugOnlyWrapper(
            builder: (context, child) => GestureDetector(
              onLongPress: () => _testInAppPurchase(context, ref),
              child: child,
            ),
            child: Button(
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
          ),
          ScreenBottomOffset(),
        ],
      ),
    );
  }

  /// Temporary test function to check IAP connectivity and product loading.
  static Future<void> _testInAppPurchase(BuildContext context, WidgetRef ref) async {
    try {
      // 1. Check store availability
      final available = await InAppPurchase.instance.isAvailable();
      Logger.log('____ IAP Test: Store available: $available');
      if (!available) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Store is not available. Please check your connection.'),
            ),
          );
        }
        return;
      }

      // 2. Get all 35 boost product IDs
      final productIds = BoostPostProducts.generateAllProductIds();
      Logger.log('____ IAP Test: Querying ${productIds.length} products: $productIds');

      final response = await InAppPurchase.instance.queryProductDetails(productIds);

      // 3. Check for errors
      if (response.error != null) {
        final error = response.error;
        Logger.log('___ IAP Test: Error Code: ${error?.code}');
        Logger.log('___ IAP Test: Error Source: ${error?.source}');
        Logger.log('___ IAP Test: Error Message: ${error?.message}');
        Logger.log('___ IAP Test: Error Details: ${error?.details}');

        Logger.log('____ IAP Test: ${error?.message}${error?.details}');

        if (context.mounted) {
          ref.read(messageNotificationNotifierProvider.notifier).show(
                MessageNotification(
                  message: '${error?.message}${error?.details}',
                  icon: Assets.svg.iconBlockTime.icon(size: 16.0.s),
                ),
              );
        }
        return;
      }

      // 4. Check for not found products
      if (response.notFoundIDs.isNotEmpty) {
        Logger.log('____ IAP Test: Not found product IDs: ${response.notFoundIDs}');
        if (context.mounted) {
          ref.read(messageNotificationNotifierProvider.notifier).show(
                MessageNotification(
                  message: '${response.notFoundIDs.length} products not found in store. '
                      'Check App Store Connect / Play Console configuration.',
                  icon: Assets.svg.iconBlockTime.icon(size: 16.0.s),
                ),
              );
        }
      }

      // 5. Display results
      final products = response.productDetails;
      Logger.log('____ IAP Test: Found ${products.length} products out of ${productIds.length}');
      for (final product in products) {
        Logger.log('____ IAP Test: Product: ${product.id} - ${product.title} - ${product.price}');
      }

      if (context.mounted) {
        ref.read(messageNotificationNotifierProvider.notifier).show(
              MessageNotification(
                message: 'IAP Test: Found ${products.length}/${productIds.length} products. '
                    'Not found: ${response.notFoundIDs.length}. Check console for details.',
                icon: Assets.svg.iconBlockTime.icon(size: 16.0.s),
              ),
            );
      }
    } catch (e) {
      Logger.log('____ IAP Test: Exception: $e');
      if (context.mounted) {
        ref.read(messageNotificationNotifierProvider.notifier).show(
              MessageNotification(
                message: 'IAP Test failed: $e',
                icon: Assets.svg.iconBlockTime.icon(size: 16.0.s),
              ),
            );
      }
    }
  }
}

class _DebugOnlyWrapper extends ConsumerWidget {
  const _DebugOnlyWrapper({
    required this.child,
    required this.builder,
  });

  final Widget child;
  final Widget Function(BuildContext context, Widget child) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDebugInfo = ref.watch(envProvider.notifier).get<bool>(EnvVariable.SHOW_DEBUG_INFO);

    return showDebugInfo ? builder(context, child) : child;
  }
}
