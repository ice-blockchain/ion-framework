// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';

class FakeWallet {
  static Wallet create({
    required String id,
    required String network,
    required String address,
    String status = 'active',
    String? name,
    String scheme = 'Ed25519',
    String curve = 'Ed25519',
    String? publicKey,
  }) {
    return Wallet(
      id: id,
      network: network,
      address: address,
      status: status,
      name: name ?? '${id.toUpperCase()} Wallet',
      signingKey: WalletSigningKey(
        scheme: scheme,
        curve: curve,
        publicKey: publicKey ?? 'key_$id',
        id: 'key_$id',
      ),
    );
  }

  static List<Wallet> createStandardWallets() {
    return [
      create(
        id: 'wallet1',
        network: 'network1',
        address: 'address1',
        name: 'Bitcoin Wallet',
      ),
      create(
        id: 'wallet2',
        network: 'network2',
        address: 'address2',
        name: 'Ethereum Wallet',
      ),
      create(
        id: 'wallet3',
        network: 'network3',
        address: 'address3',
        name: 'Solana Wallet',
      ),
      create(
        id: 'wallet4',
        network: 'network4',
        address: 'address4',
        name: 'Cardano Wallet',
      ),
    ];
  }
}
