// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/services.dart';

/// Class representing the Appodeal Consent Form logic for IAB TCFv2 and Google UMP.
class AppodealConsentForm {
  const AppodealConsentForm();

  /// Private method channel for communicating with native platform.
  static const MethodChannel _consentManagerChannel =
      MethodChannel('appodeal_flutter/consent_manager');

  /// Load consent form to determine the user's consent preferences.
  ///
  /// Parameters:
  /// - [appKey]: The Appodeal application key.
  /// - [tagForUnderAgeOfConsent]: Flag to tag the user as under the age of consent.
  /// - [onConsentFormLoadSuccess]: Callback for successful consent form loading.
  /// - [onConsentFormLoadFailure]: Callback for failed consent form loading.
  Future<void> load({
    required String appKey,
    bool tagForUnderAgeOfConsent = false,
    void Function(ConsentStatus)? onConsentFormLoadSuccess,
    void Function(ConsentError)? onConsentFormLoadFailure,
  }) {
    _setHandler({
      'onConsentFormLoadSuccess': (arguments) {
        final status = _ConsentStatusExtension._fromInt(arguments['status'] as int);
        onConsentFormLoadSuccess?.call(status);
      },
      'onConsentFormLoadFailure': (arguments) {
        final error = ConsentError._(arguments['error'] as String? ?? '');
        onConsentFormLoadFailure?.call(error);
      },
    });

    return _invokeMethod('load', {
      'appKey': appKey,
      'tagForUnderAgeOfConsent': tagForUnderAgeOfConsent,
    });
  }

  /// Show the consent form to determine the user's consent.
  ///
  /// Parameters:
  /// - [onConsentFormDismissed]: Callback for when the consent form is dismissed.
  void show({
    void Function(ConsentError? error)? onConsentFormDismissed,
  }) {
    _setHandler({
      'onConsentFormDismissed': (arguments) {
        final error = arguments?['error'] != null
            ? ConsentError._(arguments['error'] as String? ?? '')
            : null;
        onConsentFormDismissed?.call(error);
      },
    });

    _invokeMethod('show');
  }

  /// Load and show the consent form to determine the user's consent if required.
  ///
  /// Parameters:
  /// - [appKey]: The Appodeal application key.
  /// - [tagForUnderAgeOfConsent]: Flag to tag the user as under the age of consent.
  /// - [onConsentFormDismissed]: Callback for when the consent form is dismissed.
  void loadAndShowIfRequired({
    required String appKey,
    bool tagForUnderAgeOfConsent = false,
    void Function(ConsentError? error)? onConsentFormDismissed,
  }) {
    _setHandler({
      'onConsentFormDismissed': (arguments) {
        final error = arguments?['error'] != null
            ? ConsentError._(arguments['error'] as String? ?? '')
            : null;
        onConsentFormDismissed?.call(error);
      },
    });

    _invokeMethod('loadAndShowIfRequired', {
      'appKey': appKey,
      'tagForUnderAgeOfConsent': tagForUnderAgeOfConsent,
    });
  }

  /// Revokes the user's consent.
  void revoke() {
    _invokeMethod('revoke');
  }

  /// Helper method to set a method call handler with specific callbacks.
  void _setHandler(Map<String, void Function(dynamic arguments)> handlers) {
    _consentManagerChannel.setMethodCallHandler((call) async {
      final handler = handlers[call.method];
      if (handler != null) {
        handler(call.arguments);
      }
    });
  }

  /// Helper method to invoke a method on the platform channel.
  Future<void> _invokeMethod(String method, [Map<String, dynamic>? arguments]) {
    return _consentManagerChannel.invokeMethod(method, arguments);
  }
}

/// Appodeal SDK Consent Error class.
///
/// This class declares errors during consent behavior.
class ConsentError {
  ConsentError._(this.description);

  /// A description of the consent error.
  final String description;

  @override
  String toString() => 'ConsentError(description: $description)';
}

/// Appodeal SDK Consent Status enum.
enum ConsentStatus {
  /// Represents an unknown consent status.
  unknown,

  /// Represents a required consent status.
  required,

  /// Represents a not required consent status.
  notRequired,

  /// Represents an obtained consent status.
  obtained
}

/// Extension on [ConsentStatus] for converting from integer values.
extension _ConsentStatusExtension on ConsentStatus {
  /// Converts an integer to a [ConsentStatus] enum value.
  static ConsentStatus _fromInt(int value) {
    switch (value) {
      case 0:
        return ConsentStatus.unknown;
      case 1:
        return ConsentStatus.required;
      case 2:
        return ConsentStatus.notRequired;
      case 3:
        return ConsentStatus.obtained;
      default:
        return ConsentStatus.unknown;
    }
  }
}
