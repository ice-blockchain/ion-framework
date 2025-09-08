// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_confirm_password_dialog.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion_identity_client/ion_identity.dart';

typedef OnGetPassword<T> = Future<T> Function(OnPasswordFlow<T> onPasswordFlow);

Future<T> Function(OnPasswordFlow<T> onPasswordFlow) useOnGetPassword<T>() {
  final context = useContext();

  return useCallback(
    <P>(OnPasswordFlow<P> onPasswordFlow) async {
      if (!context.mounted) {
        throw VerifyIdentityException();
      }

      final maybeFuture = await showSimpleBottomSheet<P>(
        context: context,
        child: VerifyIdentityConfirmPasswordDialog<P>(
          onPasswordFlow: onPasswordFlow,
        ),
      );

      if (maybeFuture == null) {
        throw VerifyIdentityException();
      }

      return maybeFuture;
    },
    [context],
  );
}
