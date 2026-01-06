// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';

// Utility class for checking if accounts are protected from token operations.
// These are official accounts where no one can perform token operations (create, buy, sell).
// Token operations include: creating token definitions, buying tokens, and selling tokens.
class TokenOperationProtectedAccounts {
  TokenOperationProtectedAccounts._();

  // List of official account master pubkeys that are protected from token operations
  static const List<String> _protectedAccountPubkeys = [
    '9fd97c487632fad0506864d5cd2fb20e2b74ef91490ff396eebe0a5ec27e33f5',
    // 'ION_MASTERPUBKEY_HERE', // TODO: Add actual ION master pubkey
  ];

  static bool isProtectedAccount(String masterPubkey) {
    if (masterPubkey.isEmpty) {
      return false;
    }
    return _protectedAccountPubkeys.contains(masterPubkey);
  }

  // Checks if the account associated with the given event reference is protected.
  static bool isProtectedAccountEvent(EventReference eventReference) {
    return isProtectedAccount(eventReference.masterPubkey);
  }

  // Checks if the account associated with the given external address is protected.
  static bool isProtectedAccountFromExternalAddress(String externalAddress) {
    final masterPubkey = MasterPubkeyResolver.resolve(
      externalAddress,
      eventReference: null,
    );
    return isProtectedAccount(masterPubkey);
  }
}
