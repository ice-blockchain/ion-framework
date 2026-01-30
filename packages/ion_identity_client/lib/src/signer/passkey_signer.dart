// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/core/storage/local_passkey_creds_state_storage.dart';
import 'package:ion_identity_client/src/signer/dtos/dtos.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

/// The default timeout value (in milliseconds) for operations within the
/// passkey signing process.
const int defaultWaitTimeout = 60000;
const int defaultOtherDeviceWaitTimeout = 120000;

/// A configuration class for passkey-related operations, providing options
/// such as timeout settings.
class PasskeysOptions {
  /// Creates an instance of [PasskeysOptions] with the specified [timeout] and [otherDeviceTimeout].
  /// If no timeout is provided, it defaults to [defaultWaitTimeout] and [defaultOtherDeviceWaitTimeout].
  const PasskeysOptions({
    this.timeout = defaultWaitTimeout,
    this.otherDeviceTimeout = defaultOtherDeviceWaitTimeout,
  });

  /// The timeout value (in milliseconds) for passkey operations.
  final int timeout;

  /// The timeout value (in milliseconds) for passkey operations when other device is involved through QR code.
  final int otherDeviceTimeout;
}

/// A class responsible for handling passkey-based registration and signing
/// operations. It uses the provided [PasskeysOptions] to configure behavior,
/// such as operation timeouts.
class PasskeysSigner {
  /// Creates an instance of [PasskeysSigner] with the specified [options].
  /// If no options are provided, the default [PasskeysOptions] are used.
  PasskeysSigner({
    required this.localPasskeyCredsStateStorage,
    this.options = const PasskeysOptions(),
  });

  /// The configuration options for passkey operations.
  final PasskeysOptions options;
  final LocalPasskeyCredsStateStorage localPasskeyCredsStateStorage;

  /// Registers a user based on the provided [challenge], returning a
  /// [CredentialRequestData] containing the attestation data.
  ///
  /// The registration process involves interacting with a passkey authenticator
  /// and relies on the options specified in [PasskeysOptions].
  Future<CredentialRequestData> register(UserRegistrationChallenge challenge) async {
    final requestType = RegisterRequestType(
      challenge: challenge.challenge,
      relyingParty: RelyingPartyType(
        name: challenge.rp.name,
        id: challenge.rp.id,
      ),
      user: UserType(
        displayName: challenge.user.displayName,
        name: challenge.user.name,
        id: base64UrlEncode(utf8.encode(challenge.user.id)),
      ),
      authSelectionType: AuthenticatorSelectionType(
        authenticatorAttachment:
            challenge.authenticatorSelection?.authenticatorAttachment ?? 'platform',
        requireResidentKey: challenge.authenticatorSelection?.requireResidentKey ?? false,
        residentKey: challenge.authenticatorSelection?.residentKey ?? 'required',
        userVerification: challenge.authenticatorSelection?.userVerification ?? 'required',
      ),
      pubKeyCredParams: List<PubKeyCredParamType>.from(
        challenge.pubKeyCredParams.map(
          (e) => PubKeyCredParamType(
            type: e.type,
            alg: e.alg,
          ),
        ),
      ),
      timeout: options.timeout,
      attestation: challenge.attestation,
      excludeCredentials: List<CredentialType>.from(
        challenge.excludeCredentials.map(
          (e) => CredentialType(
            type: e.type,
            id: e.id,
            transports: [],
          ),
        ),
      ),
    );

    try {
      final registerResponse = await PasskeyAuthenticator().register(requestType);

      return CredentialRequestData(
        credentialInfo: CredentialInfo(
          attestationData: registerResponse.attestationObject,
          clientData: registerResponse.clientDataJSON,
          credId: registerResponse.rawId,
        ),
        credentialKind: CredentialKind.Fido2,
      );
    } on PasskeyAuthCancelledException {
      throw const PasskeyCancelledException();
    } catch (e) {
      if (PasskeyCancelledException.isMatch(e)) {
        throw const PasskeyCancelledException();
      }
      rethrow;
    }
  }

  /// Logs in a user based on the provided [challenge].
  ///
  /// This method attempts to authenticate the user using passkey credentials
  /// available on the current device. If no credentials are available, it updates
  /// the [localPasskeyCredsStateStorage] to indicate that the system can suggest
  /// creating new credentials and retries the sign operation without preferring
  /// immediately available credentials.
  ///
  /// - [username]: The username of the user attempting to log in.
  /// - [challenge]: The [UserActionChallenge] containing the authentication challenge.
  ///
  /// Returns an [AssertionRequestData] object containing the assertion data upon successful authentication.
  ///
  /// Throws [PasskeyValidationException] if the sign operation fails due to validation errors.
  /// Propagates [NoCredentialsAvailableException] if no credentials are available even after state update.
  Future<AssertionRequestData> login({
    required String username,
    required UserActionChallenge challenge,
    required bool localCredsOnly,
  }) async {
    try {
      return await sign(
        challenge,
        localCredsOnly: localCredsOnly,
      );
    } on NoCredentialsAvailableException {
      if (localCredsOnly && username.isNotEmpty) {
        await localPasskeyCredsStateStorage.updateLocalPasskeyCredsState(
          username: username,
          state: LocalPasskeyCredsState.canSuggest,
        );
      }
      throw const NoLocalPasskeyCredsFoundIONIdentityException();
    } on PasskeyAuthCancelledException {
      throw const PasskeyCancelledException();
    }
  }

  String _resolveRelyingId(UserActionChallenge challenge) {
    final direct = challenge.rp.id.trim();
    if (direct.isNotEmpty) {
      return direct;
    }

    throw const PasskeyCancelledException(
      'Passkey cancelled due because relying party id (rp.id) is empty',
    );
  }

  /// Signs a user action challenge, returning a [AssertionRequestData] containing
  /// the assertion data.
  ///
  /// This method interacts with a passkey authenticator to authenticate the
  /// user, utilizing the options specified in [PasskeysOptions].
  Future<AssertionRequestData> sign(
    UserActionChallenge challenge, {
    bool localCredsOnly = false,
  }) async {
    final relyingPartyId = _resolveRelyingId(challenge);
    final timeoutMs = localCredsOnly == true ? options.timeout : options.otherDeviceTimeout;
    try {
      final allowCredentials = List<CredentialType>.from(
        challenge.allowCredentials.webauthn.map(
          (e) => CredentialType(
            type: e.type,
            id: e.id,
            transports: [],
          ),
        ),
      );
      final fido2Assertion = await PasskeyAuthenticator()
          .authenticate(
        AuthenticateRequestType(
          preferImmediatelyAvailableCredentials: localCredsOnly,
          relyingPartyId: relyingPartyId,
          challenge: challenge.challenge,
          timeout: timeoutMs,
          userVerification: challenge.userVerification,
          allowCredentials: allowCredentials.isEmpty ? null : allowCredentials,
          mediation: MediationType.Required,
        ),
      )

          /// Races the platform authentication against a Dart-side watchdog timer.
          ///
          /// Some Android devices (notably with Samsung Pass / Credential Manager)
          /// occasionally never resolve the native "authenticate" call when the
          /// provider UI gets stuck enumerating credentials. The platform timeout
          /// passed to the API is not always honored; this watchdog ensures we regain
          /// control in the Dart layer and can surface a predictable error.
          .timeout(
        Duration(
          milliseconds: timeoutMs,
        ),
        onTimeout: () async {
          // Best-effort cancel of the ongoing native Credential Manager / passkey operation.
          try {
            await PasskeyAuthenticator().cancelCurrentAuthenticatorOperation();
          } catch (_) {
            // ignore: cancellation is best-effort
          }
          throw const PasskeyCancelledException('Passkey interrupted by timed out');
        },
      );
      return AssertionRequestData(
        kind: CredentialKind.Fido2,
        credentialAssertion: CredentialAssertionData(
          clientData: fido2Assertion.clientDataJSON,
          credId: fido2Assertion.rawId,
          signature: fido2Assertion.signature,
          authenticatorData: fido2Assertion.authenticatorData,
          userHandle: fido2Assertion.userHandle,
        ),
      );
    } on NoCredentialsAvailableException {
      rethrow;
    } on PasskeyCancelledException {
      rethrow;
    } on PasskeyAuthCancelledException {
      throw const PasskeyCancelledException();
    } on UnhandledAuthenticatorException catch (e) {
      if (PasskeyCancelledException.isMatch(e)) {
        throw const PasskeyCancelledException();
      }
      throw PasskeyValidationException(
        'Unhandled authenticator exception: ${e.message ?? e.toString()}',
      );
    } catch (e) {
      throw PasskeyValidationException(
        'Unexpected error during passkey validation: ${e.runtimeType}: $e',
      );
    }
  }

  Future<bool> checkPasskeyAvailability() async {
    final availability = PasskeyAuthenticator().getAvailability();

    if (kIsWeb) {
      // Web Platform
      final webAvailability = await availability.web();
      return webAvailability.hasPasskeySupport;
    } else if (Platform.isAndroid) {
      // Android Platform
      final androidAvailability = await availability.android();
      return androidAvailability.hasPasskeySupport &&
          true == androidAvailability.isUserVerifyingPlatformAuthenticatorAvailable;
    } else if (Platform.isIOS) {
      // iOS Platform
      final iosAvailability = await availability.iOS();
      return iosAvailability.hasPasskeySupport;
    }

    // ignore: deprecated_member_use
    return PasskeyAuthenticator().canAuthenticate();
  }

  Future<void> rejectToCreateLocalPasskeyCreds(String username) {
    return localPasskeyCredsStateStorage.updateLocalPasskeyCredsState(
      username: username,
      state: LocalPasskeyCredsState.rejected,
    );
  }
}
