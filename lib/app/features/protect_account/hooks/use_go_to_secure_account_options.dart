// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/user_details_provider.r.dart';
import 'package:ion/app/hooks/use_pop_until.dart';
import 'package:ion/app/router/app_routes.gr.dart';

VoidCallback useGoToSecureAccountOptions(WidgetRef ref) {
  final popUntil = usePopUntil(routeLocation: SecureAccountOptionsRoute().location);
  return useCallback(
    () {
      ref.invalidate(userDetailsProvider);
      popUntil();
    },
    [popUntil],
  );
}
