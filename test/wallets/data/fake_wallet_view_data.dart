import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';

final mockedWalletDataArray = <WalletViewData>[
  WalletViewData(
    id: '1',
    name: 'ice.wallet',
    usdBalance: 36594.33,
    coinGroups: [],
    nfts: [],
    createdAt: DateTime.now().microsecondsSinceEpoch,
    updatedAt: DateTime.now().microsecondsSinceEpoch,
    symbolGroups: {},
    isMainWalletView: false,
  ),
  WalletViewData(
    id: '2',
    name: 'Airdrop wallet',
    usdBalance: 48,
    coinGroups: [],
    nfts: [],
    createdAt: DateTime.now().microsecondsSinceEpoch,
    updatedAt: DateTime.now().microsecondsSinceEpoch,
    symbolGroups: {},
    isMainWalletView: false,
  ),
  WalletViewData(
    id: '3',
    name: 'For transfers',
    usdBalance: 279.99,
    coinGroups: [],
    nfts: [],
    createdAt: DateTime.now().microsecondsSinceEpoch,
    updatedAt: DateTime.now().microsecondsSinceEpoch,
    symbolGroups: {},
    isMainWalletView: false,
  ),
];
