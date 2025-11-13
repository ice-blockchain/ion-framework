// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart' as db;
import 'package:ion_identity_client/ion_identity.dart' as ion_identity;

part 'network_data.f.freezed.dart';

@freezed
class NetworkData with _$NetworkData {
  const factory NetworkData({
    required String id,
    required String image,
    required bool isTestnet,
    required String displayName,
    required String explorerUrl,
    required int tier,
  }) = _NetworkData;

  const NetworkData._();

  factory NetworkData.fromDB(db.Network dbInstance) => NetworkData(
        id: dbInstance.id,
        image: dbInstance.image,
        isTestnet: dbInstance.isTestnet,
        displayName: dbInstance.displayName,
        explorerUrl: dbInstance.explorerUrl,
        tier: dbInstance.tier,
      );

  factory NetworkData.fromDTO(ion_identity.Network instance) => NetworkData(
        id: instance.id,
        image: instance.image,
        isTestnet: instance.isTestnet,
        displayName: instance.displayName,
        explorerUrl: instance.explorerUrl,
        tier: instance.tier,
      );

  bool get isIonHistorySupported => tier == 1;
  bool get isMemoSupported =>
      id == 'XrpLedger' ||
      id == 'XrpLedgerTestnet' ||
      id == 'Ton' ||
      id == 'TonTestnet' ||
      id == 'Stellar' ||
      id == 'StellarTestnet';

  bool get isPolkadot => id == 'Polkadot' || id == 'Westends';
  bool get isCardano => id == 'Cardano' || id == 'CardanoPreprod';
  bool get isBitcoin => id == 'Bitcoin' || id == 'BitcoinSignet';
  bool get isAptos => id == 'Aptos' || id == 'AptosTestnet';
  bool get isSolana => id == 'Solana' || id == 'SolanaDevnet';
  bool get isTon => id == 'Ton' || id == 'TonTestnet';

  String getExplorerUrl(String txHash) => explorerUrl.replaceAll('{txHash}', txHash);
}
