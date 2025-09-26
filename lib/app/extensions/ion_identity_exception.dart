// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion_identity_client/ion_identity.dart';

extension IONIdentityExceptionTranslation on IONIdentityException {
  String title(BuildContext context) {
    switch (this) {
      case UserAlreadyExistsException():
        return context.i18n.error_identity_user_already_exists_title;
      case IdentityNotFoundIONIdentityException():
        return context.i18n.error_identity_not_found_title;
      case NoLocalPasskeyCredsFoundIONIdentityException():
        return context.i18n.error_identity_no_local_passkey_creds_found_title;
      case TwoFARequiredException():
        return context.i18n.error_identity_2fa_required_title;
      case DeviceIdentityVerificationException():
        return context.i18n.error_device_identity_error_title;
      default:
        return context.i18n.error_general_title;
    }
  }

  String description(BuildContext context) {
    switch (this) {
      case UserAlreadyExistsException():
        return context.i18n.error_identity_user_already_exists_description;
      case IdentityNotFoundIONIdentityException():
        return context.i18n.error_identity_not_found_description;
      case NoLocalPasskeyCredsFoundIONIdentityException():
        return context.i18n.error_identity_no_local_passkey_creds_found_description;
      case TwoFARequiredException():
        return context.i18n.error_identity_2fa_required_description;
      case DeviceIdentityVerificationException():
        return context.i18n.error_device_identity_error_description;
      case final RequestExecutionException exception when exception.error is DioException:
        return context.i18n.error_general_description(
          context.i18n.error_general_error_code(
            (exception.error as DioException).response?.statusCode?.toString() ?? '-1',
          ),
        );
      default:
        return context.i18n.error_general_description('');
    }
  }
}
