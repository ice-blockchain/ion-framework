// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';

/// Parameters required to sign and broadcast ION swap transactions
/// using the ion-identity clients flow (UserActionSignerNew).
class IonSwapRequest {
  IonSwapRequest({
    required this.identityClient,
    required this.wallet,
    required this.userActionSigner,
  });

  final IONIdentityClient identityClient;
  final Wallet wallet;
  final UserActionSignerNew userActionSigner;
}
