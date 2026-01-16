// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';

// Service for checking if accounts are protected from token operations.
// These are accounts where no one can perform token operations like creating token definitions, buying tokens, and selling tokens.
class TokenOperationProtectedAccountsService {
  TokenOperationProtectedAccountsService({
    required List<String> protectedAccountPubkeys,
  }) : _protectedAccountPubkeys = protectedAccountPubkeys;

  final List<String> _protectedAccountPubkeys;

  // Checks if the given master pubkey is protected from token operations.
  bool isProtectedAccount(String masterPubkey) {
    if (masterPubkey.isEmpty) {
      return false;
    }
    return _protectedAccountPubkeys.contains(masterPubkey);
  }

  // Checks if the account associated with the given event reference is protected from token operations.
  bool isProtectedAccountEvent(EventReference eventReference) {
    return isProtectedAccount(eventReference.masterPubkey);
  }

  // Checks if the account associated with the given external address is protected from token operations.
  // for x tokens external address has not a master pubkey so catch exception and return false
  bool isProtectedAccountFromExternalAddress(String externalAddress) {
    try {
      final masterPubkey = MasterPubkeyResolver.resolve(
        externalAddress,
        eventReference: null,
      );
      return isProtectedAccount(masterPubkey);
    } catch (_) {
      return false;
    }
  }
}
