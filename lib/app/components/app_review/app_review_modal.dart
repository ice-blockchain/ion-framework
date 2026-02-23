// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/app_review/rating_stars.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/services/review/app_review_controller.r.dart';
import 'package:ion/app/services/review/app_review_service.r.dart';
import 'package:ion/generated/assets.gen.dart';

class AppReviewModal extends HookConsumerWidget {
  const AppReviewModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = useState<int>(0);
    final isSubmitted = useState<bool>(false);

    Future<void> handleRating(int starRating) async {
      rating.value = starRating;

      await ref.read(appReviewControllerProvider.notifier).recordComplete();

      if (starRating == 5) {
        await ref.read(appReviewServiceProvider).requestReview();
        if (context.mounted) Navigator.pop(context);
      } else {
        isSubmitted.value = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) Navigator.pop(context);
        });
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavigationAppBar.modal(
          showBackButton: false,
          actions: [
            NavigationCloseButton(
              onPressed: () => _onDismiss(context, ref),
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isSubmitted.value
              ? const _ThanksView(key: ValueKey('thanks'))
              : _RatingView(
                  key: const ValueKey('rating'),
                  rating: rating.value,
                  onRatingChanged: handleRating,
                ),
        ),
        ScreenBottomOffset(),
      ],
    );
  }

  Future<void> _onDismiss(BuildContext context, WidgetRef ref) async {
    await ref.read(appReviewControllerProvider.notifier).recordDismiss();
    if (context.mounted) Navigator.pop(context);
  }
}

class _AppReviewHeader extends StatelessWidget {
  const _AppReviewHeader({
    required this.icon,
    required this.title,
    required this.description,
  });

  final Widget icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(height: 14.s),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.theme.appTextThemes.headline2.copyWith(
            color: context.theme.appColors.primaryText,
          ),
        ),
        SizedBox(height: 6.s),
        Text(
          description,
          textAlign: TextAlign.center,
          style: context.theme.appTextThemes.subtitle3.copyWith(
            color: context.theme.appColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _RatingView extends StatelessWidget {
  const _RatingView({required this.rating, required this.onRatingChanged, super.key});

  final int rating;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    final description = Platform.isIOS
        ? context.i18n.review_rate_app_description_ios
        : context.i18n.review_rate_app_description_android;

    return Column(
      children: [
        _AppReviewHeader(
          icon: Assets.svg.actionWalletCreatortokens.icon(size: 80.0.s),
          title: context.i18n.review_rate_app_title,
          description: description,
        ),
        SizedBox(height: 30.s),
        RatingStars(
          rating: rating,
          onRatingChanged: onRatingChanged,
        ),
      ],
    );
  }
}

class _ThanksView extends StatelessWidget {
  const _ThanksView({super.key});

  @override
  Widget build(BuildContext context) {
    return _AppReviewHeader(
      icon: Assets.svg.actionWalletCreatortokens.icon(size: 80.0.s),
      title: context.i18n.review_thank_you_title,
      description: context.i18n.review_thank_you_description,
    );
  }
}
