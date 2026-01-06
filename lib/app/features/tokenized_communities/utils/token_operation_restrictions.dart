// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';

// Utility class for checking if token operations should be restricted for accounts.
// Token operations include: creating token definitions, buying tokens, and selling tokens.
class TokenOperationRestrictions {
  TokenOperationRestrictions._();

  // List of account master pubkeys that should have token operations restricted
  static const List<String> _restrictedAccountPubkeys = [
    // 'ION_MASTERPUBKEY_HERE', // TODO: Add actual ION master pubkey
  ];

  static bool isRestrictedAccount(String masterPubkey) {
    if (masterPubkey.isEmpty) {
      return false;
    }
    return _restrictedAccountPubkeys.contains(masterPubkey);
  }

  // Checks if the account associated with the given event reference is restricted.
  static bool isRestrictedAccountEvent(EventReference eventReference) {
    return isRestrictedAccount(eventReference.masterPubkey);
  }

  // Checks if the account associated with the given external address is restricted.
  static bool isRestrictedAccountFromExternalAddress(String externalAddress) {
    final masterPubkey = MasterPubkeyResolver.resolve(
      externalAddress,
      eventReference: null,
    );
    return isRestrictedAccount(masterPubkey);
  }
}
