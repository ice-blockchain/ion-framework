// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/user_referral_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion_identity_client/ion_identity.dart';

ValueNotifier<String?> useVerifyReferralExistsErrorMessage(WidgetRef ref) {
  final context = useContext();
  final state = ref.watch(userReferralNotifierProvider);
  ref.displayErrors(
    userReferralNotifierProvider,
    excludedExceptions: {
      InvalidNicknameException,
      NicknameDoesntExistException,
      NicknameReservedException,
    },
  );

  final errorMessage = useState<String?>(null);
  useOnInit(
    () {
      if (state.hasError && !state.isLoading) {
        if (state.error is InvalidNicknameException) {
          errorMessage.value = context.i18n.error_nickname_invalid;
        }
        if (state.error is NicknameDoesntExistException ||
            state.error is NicknameReservedException) {
          errorMessage.value = context.i18n.error_nickname_not_exists;
        }
      }
    },
    [state.hasError, state.isLoading],
  );

  return errorMessage;
}
