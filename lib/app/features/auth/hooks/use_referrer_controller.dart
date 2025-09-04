// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/onboarding_data_provider.m.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/nickname_input.dart';
import 'package:ion/app/services/referrer/referrer_service.r.dart';

/// Custom hook that manages the referral input controller with automatic referrer detection
TextEditingController useReferrerController(WidgetRef ref, BuildContext context) {
  final onboardingData = ref.watch(onboardingDataProvider);
  final referrerData = ref.watch(installReferrerProvider);

  final initialReferral = onboardingData.referralName ?? '';
  final referralController = useTextEditingController(text: initialReferral);

  // Update controller when referrerData loads and controller is empty
  useEffect(
    () {
      referrerData.whenData((referrerValue) async {
        if (referrerValue != null && referrerValue.isNotEmpty && referralController.text.isEmpty) {
          // Validate the referrerData value before setting it
          final validationError = validateNickname(referrerValue, context);
          if (validationError == null) {
            referralController.text = referrerValue;
          }
        }
      });
      return null;
    },
    [referrerData, context],
  );

  return referralController;
}
