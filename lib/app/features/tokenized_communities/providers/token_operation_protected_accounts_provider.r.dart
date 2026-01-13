// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/services/token_operation_protected_accounts_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_operation_protected_accounts_provider.r.g.dart';

@Riverpod(keepAlive: true)
TokenOperationProtectedAccountsService tokenOperationProtectedAccountsService(Ref ref) {
  // TODO: Replace with remote config when backend is ready
  // final protectedAccountPubkeys = await ref.watch(protectedAccountsConfigProvider.future);
  // For now: hardcoded list
  const protectedAccountPubkeys = [
    '4df429e18a2980c17b430d9ced0f4740c7dfca5f72de714dedbd114c84b3dacf', // ICE official account master pubkey
  ];

  return TokenOperationProtectedAccountsService(
    protectedAccountPubkeys: protectedAccountPubkeys,
  );
}
