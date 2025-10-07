// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/components/biometrics/suggest_to_add_biometrics_popup.dart';
import 'package:ion/app/features/user/providers/biometrics_provider.r.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion_identity_client/ion_identity.dart';

Future<void> Function({required String username, required String password})
    useOnSuggestToAddBiometrics(WidgetRef ref) {
  final context = useContext();
  return useCallback(
    ({
      required String username,
      required String password,
    }) async {
      final userBiometricsState =
          await ref.read(userBiometricsStateProvider(username: username).future);

      if (userBiometricsState == BiometricsState.canSuggest && context.mounted) {
        // Additional check on Android, because local_auth.authorize() allows to authenticate
        // even if biometrics are not set up on the device and it leads to native crush in
        // local_auth_crypto.authenticate then. So we should not even suggest to add biometrics
        // in this case.
        if (!Platform.isAndroid ||
            await ref.read(biometricsServiceProvider).isBiometricsAvailable() && context.mounted) {
          // Show suggest to add biometrics popup
          await showSimpleBottomSheet<void>(
            context: context,
            child: SuggestToAddBiometricsPopup(
              username: username,
              password: password,
            ),
          );
        } else {
          // If biometrics are not available on Android then we should reject to use biometrics
          await ref
              .read(rejectToUseBiometricsNotifierProvider.notifier)
              .rejectToUseBiometrics(username: username, password: password);
        }
      }
    },
    [context],
  );
}
