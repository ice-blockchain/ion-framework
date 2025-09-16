// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/nickname_reserved_modal/nickname_reserved_modal.dart';
import 'package:ion/app/features/user/providers/update_user_metadata_notifier.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion_identity_client/ion_identity.dart';

ValueNotifier<String?> useUpdateUserMetadataErrorMessage(WidgetRef ref) {
  final state = ref.watch(updateUserMetadataNotifierProvider);
  ref
    ..displayErrors(
      updateUserMetadataNotifierProvider,
      excludedExceptions: {
        InvalidNicknameException,
        NicknameAlreadyExistsException,
        NicknameReservedException,
      },
    )
    ..listenError(updateUserMetadataNotifierProvider, (error) {
      if (error is NicknameReservedException) {
        showSimpleBottomSheet<void>(context: ref.context, child: const NicknameReservedModal());
      }
    });

  final errorMessage = useState<String?>(null);
  useOnInit(
    () {
      if (state.hasError && !state.isLoading) {
        if (state.error is InvalidNicknameException) {
          errorMessage.value = ref.context.i18n.error_nickname_invalid;
        } else if (state.error is NicknameAlreadyExistsException) {
          errorMessage.value = ref.context.i18n.error_nickname_taken;
        } else if (state.error is NicknameReservedException) {
          errorMessage.value = ref.context.i18n.error_nickname_reserved_title;
        }
      }
    },
    [state.hasError, state.isLoading],
  );

  return errorMessage;
}
