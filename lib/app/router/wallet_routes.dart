// SPDX-License-Identifier: ice License 1.0

part of 'app_routes.gr.dart';

class WalletRoutes {
  static const routes = <TypedRoute<RouteData>>[
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<ManageNftsRoute>(path: 'manage-nfts'),
      ],
    ),
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<SelectContactRoute>(path: 'select-contact'),
        TypedGoRoute<ContactRoute>(path: 'one-contact/:pubkey'),
        TypedGoRoute<CoinTransactionDetailsRoute>(path: 'transaction-details'),
        TypedGoRoute<ExploreTransactionDetailsRoute>(path: 'explore-transaction-details'),
        ...coinSendRoutes,
        ...coinReceiveRoutes,
        ...nftSendRoutes,
        ...swapCoinsRoutes,
      ],
    ),
    ...walletManagementRoutes,
    TypedShellRoute<ModalShellRouteData>(
      routes: [TypedGoRoute<ScanWalletRoute>(path: 'scan-wallet')],
    ),
    TypedGoRoute<CoinsDetailsRoute>(path: 'coin-details'),
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<AddressNotFoundRoute>(path: 'address-not-found'),
        TypedGoRoute<CoinReceiveRoute>(path: 'coin-receive'),
        TypedGoRoute<ShareAddressCoinDetailsRoute>(path: 'share-wallet-address'),
        TypedGoRoute<ChangeNetworkShareWalletRoute>(path: 'change-wallet-network'),
      ],
    ),
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<ManageCoinsRoute>(path: 'manage-coins'),
        TypedGoRoute<ImportTokenRoute>(path: 'import-token'),
        TypedGoRoute<SelectNetworkForTokenRoute>(path: 'select-network'),
        TypedGoRoute<ShareTokenCreatorRoute>(path: 'share-token-creator/:masterPubkey'),
      ],
    ),
    ...DappsRoutes.routes,
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<SelectNetworkToReceiveNftRoute>(path: 'select-network-to-receive-nft'),
        TypedGoRoute<ShareAddressToGetNftRoute>(path: 'share-address-to-get-nft'),
        TypedGoRoute<AddressNotFoundReceiveNftRoute>(path: 'address-not-found-receive-nft'),
      ],
    ),
  ];

  static const nftSendRoutes = <TypedRoute<RouteData>>[
    TypedGoRoute<NftDetailsRoute>(path: 'nft-details'),
    TypedGoRoute<NftSendFormRoute>(
      path: 'nft-send',
      routes: [
        TypedGoRoute<NftSelectContactRoute>(path: 'select-contact-to-send-nft'),
        TypedGoRoute<NftSendScanRoute>(path: 'scan-receiver-wallet'),
        TypedGoRoute<SendNftConfirmRoute>(path: 'nft-confirm'),
      ],
    ),
    TypedGoRoute<NftTransactionResultRoute>(path: 'nft-transaction-result'),
  ];

  static const coinSendRoutes = <TypedRoute<RouteData>>[
    TypedGoRoute<SelectCoinWalletRoute>(
      path: 'coin-send',
      routes: [
        TypedGoRoute<SelectNetworkWalletRoute>(path: 'network-select'),
        TypedGoRoute<SendCoinsFormWalletRoute>(
          path: 'coin-send-form',
          routes: [
            TypedGoRoute<SelectContactWalletRoute>(path: 'select-contact-to-send_coins'),
            TypedGoRoute<ShareAddressDepositRoute>(path: 'share-address-to-deposit'),
          ],
        ),
        TypedGoRoute<CoinSendScanRoute>(path: 'scan-receiver-wallet'),
        TypedGoRoute<SendCoinsConfirmationWalletRoute>(path: 'coin-send-form-confirmation'),
      ],
    ),
    TypedGoRoute<CoinTransactionResultWalletRoute>(path: 'coin-transaction-result'),
  ];

  static const coinReceiveRoutes = <TypedRoute<RouteData>>[
    TypedGoRoute<ReceiveCoinRoute>(
      path: 'receive-coin',
      routes: [
        TypedGoRoute<NetworkSelectReceiveRoute>(path: 'network-select-receive'),
      ],
    ),
    TypedGoRoute<ShareAddressToGetCoinsRoute>(path: 'share-address'),
    TypedGoRoute<AddressNotFoundReceiveCoinsRoute>(path: 'address-not-found-receive'),
  ];

  static const walletManagementRoutes = <TypedRoute<RouteData>>[
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<WalletsRoute>(path: 'wallets'),
        TypedGoRoute<ManageWalletsRoute>(path: 'manage-wallets'),
        TypedGoRoute<CreateWalletRoute>(path: 'create-wallet'),
        TypedGoRoute<EditWalletRoute>(path: 'edit-wallet'),
        TypedGoRoute<DeleteWalletRoute>(path: 'delete-wallet'),
      ],
    ),
  ];

  static const swapCoinsRoutes = <TypedRoute<RouteData>>[
    TypedGoRoute<SwapCoinsRoute>(path: 'swap-coins'),
  ];
}

class ManageNftsRoute extends BaseRouteData with _$ManageNftsRoute {
  ManageNftsRoute()
      : super(
          child: const ManageNftsPage(),
          type: IceRouteType.bottomSheet,
        );
}

class CoinSendScanRoute extends BaseRouteData with _$CoinSendScanRoute {
  CoinSendScanRoute()
      : super(
          child: const WalletScanModalPage(),
          type: IceRouteType.bottomSheet,
        );
}

class SelectCoinWalletRoute extends BaseRouteData with _$SelectCoinWalletRoute {
  SelectCoinWalletRoute()
      : super(
          child: SendCoinModalPage(
            selectNetworkRouteLocationBuilder: () => SelectNetworkWalletRoute().location,
          ),
          type: IceRouteType.bottomSheet,
        );
}

class ReceiveCoinRoute extends BaseRouteData with _$ReceiveCoinRoute {
  ReceiveCoinRoute()
      : super(
          child: const ReceiveCoinModalPage(),
          type: IceRouteType.bottomSheet,
        );
}

class ScanWalletRoute extends BaseRouteData with _$ScanWalletRoute {
  ScanWalletRoute()
      : super(
          child: const WalletScanModalPage(),
          type: IceRouteType.bottomSheet,
        );
}

class NetworkSelectReceiveRoute extends BaseRouteData with _$NetworkSelectReceiveRoute {
  NetworkSelectReceiveRoute()
      : super(
          child: const NetworkListView(type: NetworkListViewType.receive),
          type: IceRouteType.bottomSheet,
        );
}

class SelectNetworkWalletRoute extends BaseRouteData with _$SelectNetworkWalletRoute {
  SelectNetworkWalletRoute()
      : super(
          child: NetworkListView(
            sendFormRouteLocationBuilder: () => SendCoinsFormWalletRoute().location,
          ),
          type: IceRouteType.bottomSheet,
        );
}

class ChangeNetworkShareWalletRoute extends BaseRouteData with _$ChangeNetworkShareWalletRoute {
  ChangeNetworkShareWalletRoute()
      : super(
          child: const NetworkListView(
            type: NetworkListViewType.receive,
            onSelectReturnType: true,
          ),
          type: IceRouteType.bottomSheet,
        );
}

class ShareAddressCoinDetailsRoute extends BaseRouteData with _$ShareAddressCoinDetailsRoute {
  ShareAddressCoinDetailsRoute()
      : super(
          child: const ShareAddressToGetCoinsView(),
          type: IceRouteType.bottomSheet,
        );
}

class ShareAddressDepositRoute extends BaseRouteData with _$ShareAddressDepositRoute {
  ShareAddressDepositRoute()
      : super(
          child: const ShareAddressToGetCoinsView(),
          type: IceRouteType.bottomSheet,
        );
}

class ShareAddressToGetCoinsRoute extends BaseRouteData with _$ShareAddressToGetCoinsRoute {
  ShareAddressToGetCoinsRoute()
      : super(
          child: const ShareAddressToGetCoinsView(),
          type: IceRouteType.bottomSheet,
        );
}

class ShareAddressToGetNftRoute extends BaseRouteData with _$ShareAddressToGetNftRoute {
  ShareAddressToGetNftRoute()
      : super(
          child: const ShareAddressToGetNftView(),
          type: IceRouteType.bottomSheet,
        );
}

class AddressNotFoundReceiveNftRoute extends BaseRouteData with _$AddressNotFoundReceiveNftRoute {
  AddressNotFoundReceiveNftRoute()
      : super(
          child: AddressNotFoundWalletModal(
            assetType: CryptoAssetType.nft,
            onWalletCreated: (context) => ShareAddressToGetNftRoute().replace(context),
          ),
          type: IceRouteType.bottomSheet,
        );
}

class SendCoinsFormWalletRoute extends BaseRouteData with _$SendCoinsFormWalletRoute {
  SendCoinsFormWalletRoute()
      : super(
          child: SendCoinsForm(
            selectCoinRouteLocationBuilder: () => SelectCoinWalletRoute().location,
            selectNetworkRouteLocationBuilder: () => SelectNetworkWalletRoute().location,
            selectContactRouteLocationBuilder: (networkId) => SelectContactWalletRoute(networkId: networkId).location,
            scanAddressRouteLocationBuilder: () => CoinSendScanRoute().location,
            confirmRouteLocationBuilder: () => SendCoinsConfirmationWalletRoute().location,
          ),
          type: IceRouteType.bottomSheet,
        );
}

class SelectContactWalletRoute extends BaseRouteData with _$SelectContactWalletRoute {
  SelectContactWalletRoute({required this.networkId})
      : super(
          child: ContactPickerModal(
            networkId: networkId,
            validatorType: ContactPickerValidatorType.networkWallet,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String networkId;
}

class SelectContactRoute extends BaseRouteData with _$SelectContactRoute {
  SelectContactRoute()
      : super(
          child: const ContactPickerModal(),
          type: IceRouteType.bottomSheet,
        );
}

class NftSelectContactRoute extends BaseRouteData with _$NftSelectContactRoute {
  NftSelectContactRoute({required this.networkId})
      : super(
          child: ContactPickerModal(
            networkId: networkId,
            validatorType: ContactPickerValidatorType.networkWallet,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String networkId;
}

class SendCoinsConfirmationWalletRoute extends BaseRouteData with _$SendCoinsConfirmationWalletRoute {
  SendCoinsConfirmationWalletRoute()
      : super(
          child: ConfirmationSheet(
            successRouteLocationBuilder: (walletViewId, txHash) =>
                CoinTransactionResultWalletRoute(walletViewId: walletViewId, txHash: txHash).location,
          ),
          type: IceRouteType.bottomSheet,
        );
}

class CoinTransactionResultWalletRoute extends BaseRouteData with _$CoinTransactionResultWalletRoute {
  CoinTransactionResultWalletRoute({
    required this.walletViewId,
    required this.txHash,
  }) : super(
          child: TransactionResultSheet(
            walletViewId: walletViewId,
            txHash: txHash,
            transactionDetailsRouteLocationBuilder: (walletViewId, txHash) =>
                CoinTransactionDetailsRoute(walletViewId: walletViewId, txHash: txHash).location,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String walletViewId;
  final String txHash;
}

class NftTransactionResultRoute extends BaseRouteData with _$NftTransactionResultRoute {
  NftTransactionResultRoute({
    required this.walletViewId,
    required this.txHash,
  }) : super(
          child: TransactionResultSheet(
            walletViewId: walletViewId,
            txHash: txHash,
            transactionDetailsRouteLocationBuilder: (walletViewId, txHash) =>
                CoinTransactionDetailsRoute(walletViewId: walletViewId, txHash: txHash).location,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String walletViewId;
  final String txHash;
}

class CoinsDetailsRoute extends BaseRouteData with _$CoinsDetailsRoute {
  CoinsDetailsRoute({required this.symbolGroup})
      : super(
          child: CoinDetailsPage(symbolGroup: symbolGroup),
        );

  final String symbolGroup;
}

class CoinReceiveRoute extends BaseRouteData with _$CoinReceiveRoute {
  CoinReceiveRoute()
      : super(
          child: const CoinReceiveModal(),
          type: IceRouteType.bottomSheet,
        );
}

class ManageCoinsRoute extends BaseRouteData with _$ManageCoinsRoute {
  ManageCoinsRoute()
      : super(
          child: const ManageCoinsPage(),
          type: IceRouteType.bottomSheet,
        );
}

class ImportTokenRoute extends BaseRouteData with _$ImportTokenRoute {
  ImportTokenRoute()
      : super(
          child: const ImportTokenPage(),
          type: IceRouteType.bottomSheet,
        );
}

class SelectNetworkForTokenRoute extends BaseRouteData with _$SelectNetworkForTokenRoute {
  SelectNetworkForTokenRoute()
      : super(
          child: const SelectNetworkList(),
          type: IceRouteType.bottomSheet,
        );
}

class SelectNetworkToReceiveNftRoute extends BaseRouteData with _$SelectNetworkToReceiveNftRoute {
  SelectNetworkToReceiveNftRoute()
      : super(
          child: const SelectNftNetworkPage(),
          type: IceRouteType.bottomSheet,
        );
}

class WalletsRoute extends BaseRouteData with _$WalletsRoute {
  WalletsRoute()
      : super(
          child: const WalletsModal(),
          type: IceRouteType.bottomSheet,
        );
}

class ManageWalletsRoute extends BaseRouteData with _$ManageWalletsRoute {
  ManageWalletsRoute()
      : super(
          child: const ManageWalletsModal(),
          type: IceRouteType.bottomSheet,
        );
}

class CreateWalletRoute extends BaseRouteData with _$CreateWalletRoute {
  CreateWalletRoute()
      : super(
          child: const CreateNewWalletModal(),
          type: IceRouteType.bottomSheet,
        );
}

class EditWalletRoute extends BaseRouteData with _$EditWalletRoute {
  EditWalletRoute({required this.walletId})
      : super(
          child: EditWalletModal(walletId: walletId),
          type: IceRouteType.bottomSheet,
        );

  final String walletId;
}

class DeleteWalletRoute extends BaseRouteData with _$DeleteWalletRoute {
  DeleteWalletRoute({required this.walletId})
      : super(
          child: DeleteWalletModal(walletId: walletId),
          type: IceRouteType.bottomSheet,
        );

  final String walletId;
}

class AddressNotFoundRoute extends BaseRouteData with _$AddressNotFoundRoute {
  AddressNotFoundRoute()
      : super(
          child: AddressNotFoundWalletModal(
            onWalletCreated: (context) => CoinReceiveRoute().replace(context),
          ),
          type: IceRouteType.bottomSheet,
        );
}

class AddressNotFoundReceiveCoinsRoute extends BaseRouteData with _$AddressNotFoundReceiveCoinsRoute {
  AddressNotFoundReceiveCoinsRoute()
      : super(
          child: AddressNotFoundWalletModal(
            onWalletCreated: (context) => ShareAddressToGetCoinsRoute().replace(context),
          ),
          type: IceRouteType.bottomSheet,
        );
}

class ContactRoute extends BaseRouteData with _$ContactRoute {
  ContactRoute({required this.pubkey})
      : super(
          child: ContactPage(pubkey: pubkey),
          type: IceRouteType.bottomSheet,
        );

  final String pubkey;
}

class NftDetailsRoute extends BaseRouteData with _$NftDetailsRoute {
  NftDetailsRoute({
    required this.contract,
    required this.tokenId,
  }) : super(
          child: NftDetailsPage(
            contract: contract,
            tokenId: tokenId,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String contract;
  final String tokenId;
}

class NftSendFormRoute extends BaseRouteData with _$NftSendFormRoute {
  NftSendFormRoute()
      : super(
          child: const SendNftForm(),
          type: IceRouteType.bottomSheet,
        );
}

class NftSendScanRoute extends BaseRouteData with _$NftSendScanRoute {
  NftSendScanRoute()
      : super(
          child: const WalletScanModalPage(),
          type: IceRouteType.bottomSheet,
        );
}

class SendNftConfirmRoute extends BaseRouteData with _$SendNftConfirmRoute {
  SendNftConfirmRoute()
      : super(
          child: const SendNftConfirmPage(),
          type: IceRouteType.bottomSheet,
        );
}

class CoinTransactionDetailsRoute extends BaseRouteData with _$CoinTransactionDetailsRoute {
  CoinTransactionDetailsRoute({
    required this.walletViewId,
    required this.txHash,
  }) : super(
          child: TransactionDetailsPage(
            walletViewId: walletViewId,
            txHash: txHash,
            exploreRouteLocationBuilder: (url) => ExploreTransactionDetailsRoute(url: url).location,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String walletViewId;
  final String txHash;
}

class ExploreTransactionDetailsRoute extends BaseRouteData with _$ExploreTransactionDetailsRoute {
  ExploreTransactionDetailsRoute({required this.url})
      : super(
          child: ExploreTransactionDetailsModal(url: url),
          type: IceRouteType.bottomSheet,
        );

  final String url;
}

class ShareTokenCreatorRoute extends BaseRouteData with _$ShareTokenCreatorRoute {
  ShareTokenCreatorRoute({required this.masterPubkey})
      : super(
          child: ShareTokenCreatorPage(masterPubkey: masterPubkey),
          type: IceRouteType.bottomSheet,
        );

  final String masterPubkey;
}

class SwapCoinsRoute extends BaseRouteData with _$SwapCoinsRoute {
  SwapCoinsRoute({required this.initialCoinsGroupSymbol})
      : super(
          child: SwapCoinsModalPage(initialCoinsGroupSymbol: initialCoinsGroupSymbol),
          type: IceRouteType.bottomSheet,
        );

  final String initialCoinsGroupSymbol;
}
