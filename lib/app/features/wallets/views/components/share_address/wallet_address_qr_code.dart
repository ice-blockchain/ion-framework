part of 'receive_info_card.dart';

class _WalletAddressQrCode extends StatelessWidget {
  const _WalletAddressQrCode({
    required this.network,
    required this.coinsGroup,
    required this.walletAddress,
  });

  final NetworkData network;
  final String? walletAddress;
  final CoinsGroup? coinsGroup;

  @override
  Widget build(BuildContext context) {
    final qrCodeSize = 150.s;

    return Column(
      children: [
        if (coinsGroup != null) ...[
          CoinIconWithNetwork.medium(
            coinsGroup!.iconUrl,
            network: network,
          ),
          SizedBox(height: 10.0.s),
          Text(
            coinsGroup!.abbreviation,
            style: context.theme.appTextThemes.body.copyWith(
              color: context.theme.appColors.primaryText,
            ),
          ),
          Text('(${network.displayName})'),
        ] else ...[
          NetworkIconWidget(
            type: WalletItemIconType.huge(),
            imageUrl: network.image,
          ),
          SizedBox(height: 10.0.s),
          Text(
            network.displayName,
            style: context.theme.appTextThemes.body.copyWith(
              color: context.theme.appColors.primaryText,
            ),
          ),
        ],
        SizedBox(height: 8.0.s),
        if (walletAddress.isNotEmpty)
          SizedBox(
            width: qrCodeSize,
            height: qrCodeSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0.s),
              child: QrImageView(
                padding: EdgeInsets.all(16.s),
                backgroundColor: context.theme.appColors.secondaryBackground,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: context.theme.appColors.primaryText,
                ),
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: Size(40.0.s, 40.0.s),
                ),
                embeddedImage: AssetImage(Assets.images.qrCode.qrCodeLogo.path),
                data: walletAddress!,
                size: qrCodeSize,
              ),
            ),
          )
        else
          Skeleton(
            child: SizedBox.square(dimension: qrCodeSize),
          ),
      ],
    );
  }
}
